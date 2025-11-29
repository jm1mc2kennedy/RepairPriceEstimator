# Repair Price Estimator

Professional jewelry repair pricing and quote management system for retail jewelry stores.

## Overview

The Repair Price Estimator is an iOS app designed to streamline the repair quote process for jewelry retail businesses. It provides standardized pricing, centralized rate management, and comprehensive quote tracking with CloudKit synchronization.

## Key Features

### 🔧 **Repair Pricing**
- Automated pricing calculations based on business rules
- Metal market rate integration (gold, silver, platinum)
- Labor time estimation and costing
- Rush job multipliers (configurable, default 1.5×)
- Manual override capabilities with approval workflows

### 📋 **Quote Management**
- Human-readable Quote IDs (Q-2025-000123 format)
- Multi-step quote creation workflow
- Photo capture and attachment
- Quote status tracking (Draft → Presented → Approved → Completed)
- Email and SMS sharing capabilities

### 👥 **Customer Management**
- Guest profile management
- Quote history tracking
- Contact information storage
- Quick access to previous repairs

### 🛡️ **Admin Controls**
- Service type configuration and SKU management
- Pricing rule and formula management
- Metal market rate updates
- Labor rate configuration
- User role management (SUPERADMIN, ADMIN, STORE_MANAGER, ASSOCIATE, BENCH_JEWELER)

### ☁️ **Cloud Synchronization**
- Full CloudKit integration for cross-device sync
- Multi-store, multi-company support
- Offline capability with automatic sync
- Secure data isolation between companies

## Architecture

### **Tech Stack**
- **Language**: Swift 6 with strict concurrency
- **UI Framework**: SwiftUI
- **Backend**: CloudKit (private database)
- **Architecture**: MVVM + Services
- **Platform**: iOS 17.0+

### **Project Structure**
```
RepairPriceEstimator/
├── RepairPriceEstimator/
│   ├── RepairPriceEstimatorApp.swift     # Main app entry point
│   ├── Core/
│   │   ├── Models/                       # Data models
│   │   │   ├── Company.swift
│   │   │   ├── Store.swift
│   │   │   ├── User.swift
│   │   │   ├── Guest.swift
│   │   │   ├── Quote.swift
│   │   │   ├── QuoteLineItem.swift
│   │   │   ├── QuotePhoto.swift
│   │   │   ├── ServiceType.swift
│   │   │   ├── PricingRule.swift
│   │   │   ├── MetalMarketRate.swift
│   │   │   └── LaborRate.swift
│   │   ├── Services/                     # Business logic
│   │   │   ├── CloudKitRepository.swift
│   │   │   ├── CloudKitService.swift
│   │   │   ├── PricingEngine.swift
│   │   │   ├── BootstrapService.swift
│   │   │   ├── AuthService.swift
│   │   │   └── QuoteIDGenerator.swift
│   │   ├── ViewModels/                   # Presentation logic
│   │   └── Persistence/                  # CloudKit mappings
│   ├── Features/                         # Feature modules
│   │   ├── Auth/
│   │   ├── Home/
│   │   ├── Quotes/
│   │   ├── Guests/
│   │   └── Admin/
│   └── Shared/                          # Reusable components
│       ├── Components/
│       └── DesignSystem/
├── RepairPriceEstimatorTests/           # Unit tests
└── README.md
```

## Getting Started

### **Prerequisites**
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Apple Developer Account (for CloudKit)
- macOS 14.0+ (for development)

### **Installation Steps**

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-org/RepairPriceEstimator.git
   cd RepairPriceEstimator
   ```

2. **Open in Xcode**
   ```bash
   open RepairPriceEstimator.xcodeproj
   ```

3. **Configure CloudKit**
   - Set up CloudKit container in Apple Developer portal
   - Update container identifier in `RepairPriceEstimator.entitlements`
   - Deploy CloudKit schema (see CloudKit Setup below)

4. **Update Bundle Identifier**
   - Change bundle identifier to match your Apple Developer account
   - Update in Project Settings → Signing & Capabilities

5. **Build and Run**
   - Select target device or simulator
   - Build and run the project (⌘+R)

## CloudKit Setup

### **Container Configuration**

1. **Create CloudKit Container**
   - Go to [Apple Developer Portal](https://developer.apple.com)
   - Navigate to Certificates, Identifiers & Profiles → CloudKit Containers
   - Create new container: `iCloud.com.jewelryrepair.estimator`

2. **Configure Record Types**
   
   The app uses the following CloudKit record types:
   
   ```
   Company
   ├── id (String)
   ├── name (String)
   ├── primaryContactInfo (String)
   └── createdAt (Date/Time)
   
   Store
   ├── id (String)
   ├── companyId (String, Reference to Company)
   ├── name (String)
   ├── storeCode (String)
   ├── location (String)
   ├── phone (String)
   └── isActive (Int(64))
   
   User
   ├── id (String)
   ├── companyId (String, Reference to Company)
   ├── storeIds (String List)
   ├── role (String)
   ├── displayName (String)
   ├── email (String)
   └── isActive (Int(64))
   
   Quote
   ├── id (String)
   ├── companyId (String, Reference to Company)
   ├── storeId (String, Reference to Store)
   ├── guestId (String, Reference to Guest)
   ├── status (String)
   ├── createdAt (Date/Time)
   ├── updatedAt (Date/Time)
   ├── validUntil (Date/Time)
   ├── currencyCode (String)
   ├── subtotal (Double)
   ├── tax (Double)
   ├── total (Double)
   ├── rushMultiplierApplied (Double)
   ├── pricingVersion (String)
   ├── internalNotes (String)
   └── customerFacingNotes (String)
   
   [Additional record types: Guest, QuoteLineItem, ServiceType, 
    PricingRule, MetalMarketRate, LaborRate, QuotePhoto]
   ```

3. **Set Security Roles**
   - Configure read/write permissions for private database
   - Set up indexes for frequently queried fields

### **Schema Deployment**

```bash
# Deploy schema using CloudKit Console or API
# Ensure all record types and fields match the app models
```


## Pricing Engine

### **Calculation Formula**

The pricing engine uses the following calculation:

```
Base Cost = Metal Cost + Labor Cost + Fixed Fees

Metal Cost = Metal Weight (g) × Metal Rate ($/g)
Labor Cost = Labor Time (hours) × Labor Rate ($/hour)

Retail Price = Base Cost + Markups
Final Price = Retail Price × Rush Multiplier (if rush)

If Final Price < Minimum Charge:
    Final Price = Minimum Charge
```

### **Configuration**

Pricing rules are configurable per company:

```swift
PricingFormula(
    metalMarkupPercentage: 2.0,    // 200% markup on metal
    laborMarkupPercentage: 1.5,    // 150% markup on labor  
    fixedFee: 10.0,                // $10 fixed fee
    rushMultiplier: 1.5,           // 1.5× for rush jobs
    minimumCharge: 25.0            // $25 minimum charge
)
```

## Quote ID System

Quotes use human-readable IDs in the format: `Q-YYYY-NNNNNN`

- **Q**: Fixed prefix
- **YYYY**: Current year
- **NNNNNN**: Sequential number (6 digits, zero-padded)

Examples: `Q-2025-000001`, `Q-2025-000123`, `Q-2025-001456`

## Multi-Tenancy

The app supports multiple companies and stores:

- **Company Level**: Top-level organization
- **Store Level**: Individual store locations
- **Data Isolation**: All queries scoped by `companyId`
- **User Access**: Role-based permissions per store/company

## Development

### **Running Tests**

```bash
# Run unit tests
⌘+U in Xcode

# Run specific test class
xcodebuild test -project RepairPriceEstimator.xcodeproj -scheme RepairPriceEstimator -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:RepairPriceEstimatorTests/PricingEngineTests
```

### **Code Style**

The project follows Swift conventions:
- Swift 6 strict concurrency
- MVVM architecture
- Protocol-oriented design
- Comprehensive error handling

### **Key Services**

#### **PricingEngine**
Handles all pricing calculations with rush multipliers and business rules.

#### **QuoteIDGenerator**
Generates unique, sequential Quote IDs with year-based numbering.

#### **CloudKitService**
Manages CloudKit operations with offline support and error handling.

#### **AuthService**
Handles authentication and role-based access control.

#### **BootstrapService**
Seeds initial data for new installations.

## Troubleshooting

### **Common Issues**

**CloudKit Authentication**
- Ensure user is signed into iCloud
- Verify CloudKit container configuration
- Check network connectivity

**Quote ID Conflicts**
- IDs are automatically generated and checked for uniqueness
- If conflicts occur, the generator will retry with next sequence

**Pricing Calculations**
- Verify metal market rates are up to date
- Check labor rates for bench jeweler role
- Ensure pricing rules are configured

**Build Errors**
- Clean build folder (⇧+⌘+K)
- Reset simulator if needed
- Verify Swift 6 concurrency compliance

### **Debug Logs**

The app provides detailed logging:
```
🌐 CloudKitService: Initializing...
🚀 Bootstrapping initial system data...
✅ Generated unique Quote ID: Q-2025-000123
💰 Calculating price for Ring Sizing Up...
```

## Production Deployment

### **Pre-Production Checklist**

- [ ] Update default admin credentials
- [ ] Configure production CloudKit container
- [ ] Test CloudKit schema in production environment
- [ ] Verify multi-store data isolation
- [ ] Test offline/online sync behavior
- [ ] Configure App Store metadata

### **CloudKit Production**

- Deploy schema to production CloudKit environment
- Configure subscription settings for real-time updates
- Set up CloudKit Console monitoring
- Test with production Apple IDs

## Support

### **Documentation**
- API documentation in source code
- Inline code comments for complex logic
- Architecture decision records in commit messages

### **Contributing**
1. Fork the repository
2. Create a feature branch
3. Follow existing code conventions
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

## License

[Specify License Type]

---

**© 2025 Repair Price Estimator**  
Professional jewelry repair pricing and quote management system.
