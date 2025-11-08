# RENT.GOA Fleet Management App - Architecture

## Overview
A mobile-first Flutter prototype for rental car fleet management with clean UI, static mock data, and sparkline visualizations.

## Status: ✅ Complete

All screens and features have been implemented with fade transitions, static mock data, and sparkline charts.

## Design System
- **Theme**: Light mode, clean fleet management aesthetic
- **Primary Color**: Black (#000000)
- **Typography**: Inter font family with generous spacing
- **Animations**: Fade transitions between screens
- **Components**: Rounded cards (12dp), no heavy shadows, flat design

## Screen Structure

### 1. Login Screen
- Entry point of the app
- Email and password fields
- Login button navigates to Fleet tab
- Static "Powered by Supabase" footer

### 2. Main Navigation (Bottom Navigation Bar)
Four tabs:
- Fleet (index 0)
- Alerts (index 1)
- Add Vehicle (index 2)
- Profile (index 3)

### 3. Fleet Screen
- KPI cards: Total Vehicles, Active Alerts, Healthy Vehicles
- Search bar for filtering by plate/model/driver
- Vehicle list with plate, model, status, timestamp
- Tap vehicle → Vehicle Detail screen
- Empty state illustration

### 4. Vehicle Detail Screen
- Material TabBar with 5 tabs:
  - Overview: Summary cards for all sensors
  - Alcohol: Level, threshold, sparkline, status badge
  - OBD: Engine, battery, speed, temperature with sparklines
  - Dashcam: Placeholder
  - Internal Cam: Placeholder

### 5. Alerts Screen
- Slide-in banner for new alerts
- Alert cards: vehicle, sensor, severity, timestamp
- Tap → Alert Detail screen with acknowledge button

### 6. Add Vehicle Screen
- Scrollable form with fields:
  - Brand, Model, Year, Fuel Type, Color
  - Plate Number, Device IDs, Photos
- Submit button (mock only)

### 7. Profile Screen
- Editable fields: Name, Company, Contact, Email (read-only)
- Save and Logout buttons

## Data Models

### Vehicle Model
- id, brand, model, year, fuelType, color
- plateNumber, deviceIds, photoUrls
- status (healthy, warning, critical)
- lastReading timestamp
- Sensor readings: alcohol, obd metrics

### Alert Model
- id, vehicleId, vehicleName
- sensorType, severity (critical, warning, info)
- reading, threshold, timestamp
- acknowledged status

### User Model
- name, company, contactNumber, email

### SensorReading Model
- timestamp, value
- For sparkline data points

## Services
No backend integration - all static mock data defined in service classes:
- VehicleService: Mock vehicle data with sensor readings
- AlertService: Mock alerts data
- UserService: Mock user profile data

## Key Components
- KPICard: Reusable stat display
- VehicleCard: List item for vehicles
- AlertCard: Alert list item
- SparklineChart: Mini line chart component
- StatusBadge: Color-coded status indicator
- SearchBar: Custom search input
- EmptyState: Illustration + message

## Technical Stack
- Flutter 3.x with Material 3
- fl_chart for sparkline charts
- google_fonts for Inter typography
- Static mock data (no backend)

## Implementation Priority
1. Update theme with black primary color and fleet management aesthetic
2. Create data models (Vehicle, Alert, User, SensorReading)
3. Create mock data services
4. Build reusable components (KPICard, SparklineChart, StatusBadge, etc.)
5. Implement Login screen
6. Implement main navigation shell with bottom nav
7. Build Fleet screen with KPIs and vehicle list
8. Build Vehicle Detail screen with tabs and sparklines
9. Build Alerts screen with cards and detail view
10. Build Add Vehicle form screen
11. Build Profile screen
12. Add fade transitions
13. Test and debug with compile_project
