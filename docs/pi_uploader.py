"""
pi_uploader.py - Raspberry Pi sensor data uploader for Rent.Goa Provider App.

Reads from a shared queue populated by GPS, OBD, and alcohol sensor threads.
Batches readings every INTERVAL_SEC seconds and uploads to the Supabase
'sensor_data' table.

Supabase sensor_data table schema:
    id                bigint (auto)
    vehicle_id        uuid
    created_at        timestamptz
    alcohol_level     text        ("Sober" | "Light drinking" | "Drunk" | "Intoxicated")
    fuel_level        numeric
    speed             numeric
    engine_temperature numeric
    latitude          numeric
    longitude         numeric

NOTE: rpm is used locally for spike detection only - it is NOT a column in sensor_data.
"""

import time
from collections import deque
from datetime import datetime
from queue import Empty

from supabase import create_client

# ---------- CONFIG ----------
SUPABASE_URL = "your_supabase_url"
SUPABASE_KEY = "your_supabase_anon_or_service_key"
VEHICLE_ID   = "your_vehicle_uuid"
INTERVAL_SEC = 5   # how often to upload a reading

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Keep last few OBD readings (for spike detection only)
obd_history = deque(maxlen=5)


# -------- EVENT DETECTION --------
def obd_event_detected(history):
    """Detect spike in speed or RPM between consecutive readings."""
    if len(history) < 2:
        return False

    prev = history[-2]
    curr = history[-1]

    SPEED_SPIKE = 15   # km/h per second
    RPM_SPIKE   = 1000 # RPM per second

    speed_spike = (
        prev.get("speed") is not None and
        curr.get("speed") is not None and
        abs(curr["speed"] - prev["speed"]) > SPEED_SPIKE
    )
    rpm_spike = (
        prev.get("rpm") is not None and
        curr.get("rpm") is not None and
        abs(curr["rpm"] - prev["rpm"]) > RPM_SPIKE
    )

    if speed_spike or rpm_spike:
        print("⚡ OBD EVENT DETECTED:", {
            "speed_spike": speed_spike,
            "rpm_spike": rpm_spike,
        })
        return True

    return False



# -------- ALCOHOL LEVEL MAPPER --------
# The sensor gives a raw float (e.g. 0.017 from ADS1115 voltage).
# BUT the Supabase column is TEXT: map the value to a string category.
# ADS1115 voltage thresholds (adjust to match your MQ3 calibration):
#   Sober:          0.0  - 0.4 V
#   Light drinking: 0.4  - 1.2 V
#   Drunk:          1.2  - 2.2 V
#   Intoxicated:    2.2+ V
def alcohol_to_category(voltage: float | None) -> str:
    if voltage is None:
        return "Sober"
    if voltage < 0.4:
        return "Sober"
    elif voltage < 1.2:
        return "Light drinking"
    elif voltage < 2.2:
        return "Drunk"
    else:
        return "Intoxicated"


# -------- MAIN SENDER --------
def Send_Supa(queue, event_flag):
    """
    Reads sensor messages from `queue`, batches them, and uploads to Supabase.

    `latest` only tracks fields that exist in the sensor_data table.
    `rpm` is intentionally excluded: it is stored only in obd_history
    for local spike detection and is NOT sent to Supabase.
    """
    print("Supabase uploader started")

    # Only fields that exist in the sensor_data Supabase table
    latest = {
        "latitude":           None,
        "longitude":          None,
        "speed":              None,
        "engine_temperature": None,
        "fuel_level":         None,
        "alcohol_level":      "Sober",  # Default: always a string
    }

    while True:
        deadline = time.time() + INTERVAL_SEC

        while time.time() < deadline:
            try:
                msg = queue.get(timeout=1)

                # -------- GPS --------
                if msg["type"] == "gps":
                    latest["latitude"]  = msg.get("latitude")
                    latest["longitude"] = msg.get("longitude")

                # -------- OBD --------
                elif msg["type"] == "OBD":
                    latest["speed"]              = msg.get("speed")
                    latest["engine_temperature"] = msg.get("engine_temperature")
                    latest["fuel_level"]         = msg.get("fuel_level")

                    # rpm lives ONLY in obd_history - never in `latest`
                    obd_history.append({
                        "speed": latest["speed"],
                        "rpm":   msg.get("rpm"),   # local spike detection only
                        "time":  time.time(),
                    })

                    if obd_event_detected(obd_history):
                        event_flag.value = True

                # -------- ALCOHOL --------
                elif msg["type"] == "alcohol":
                    raw = msg.get("alcohol_level")
                    # If the sensor sends a raw voltage float -> map to text
                    # If it already sends a string -> use it directly
                    if isinstance(raw, str):
                        latest["alcohol_level"] = raw
                    else:
                        latest["alcohol_level"] = alcohol_to_category(raw)

            except Empty:
                pass

        # -------- UPLOAD --------
        payload = {
            "vehicle_id": VEHICLE_ID,
            "created_at": datetime.utcnow().isoformat(),
            **latest,   # safe: rpm is not in `latest`
        }

        try:
            response = supabase.table("sensor_data").insert(payload).execute()
            # supabase-py does NOT raise exceptions for API errors:
            # we must check the response explicitly
            if not response.data:
                print(f"⚠️  Supabase insert failed: no data returned. Payload: {payload}")
            else:
                print(f"✅ Uploaded: alcohol={latest['alcohol_level']} speed={latest['speed']} temp={latest['engine_temperature']}")
        except Exception as e:
            print("Supabase exception:", e)
