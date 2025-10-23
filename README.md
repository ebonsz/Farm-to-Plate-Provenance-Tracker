# 🌾 Farm-to-Plate Provenance Tracker

A blockchain-based solution for tracking food products from farm to restaurant, ensuring transparency and freshness verification through QR codes.

## 🎯 Overview

This Clarity smart contract enables restaurants to display QR codes that customers can scan to verify the origin, journey, and freshness history of their food. All supply chain data is stored immutably on the Stacks blockchain.

## ✨ Features

- 🏭 **Supplier Registration** - Register and verify suppliers with certifications
- 📦 **Product Registration** - Track products from harvest with origin details
- 🚚 **Journey Tracking** - Record each stage: harvested → processed → distributed → delivered
- 📝 **Supplier Attestations** - Verified suppliers can attest to product quality
- 🌡️ **Temperature Monitoring** - Optional temperature data at each stage
- ⏱️ **Freshness Verification** - Calculate blocks elapsed since harvest
- 🍽️ **Restaurant Assignment** - Link products to specific restaurants
- 🔍 **QR Code Integration** - Query product data via product ID

## 📋 Contract Functions

### Public Functions

#### `register-supplier`
Register as a supplier in the system.
```clarity
(register-supplier "Farm Name" "Organic Farm" "USDA Organic")
```

#### `verify-supplier`
Contract owner verifies a supplier (required for attestations).
```clarity
(verify-supplier 'SP2...)
```

#### `register-product`
Create a new product entry with origin and initial location.
```clarity
(register-product "Organic Tomatoes" "Valley Farm, CA" "Vegetables" "Valley Farm Greenhouse" (some 5) "Freshly harvested")
```

#### `update-product-status`
Update product status through the supply chain (harvested → processed → distributed → delivered).
```clarity
(update-product-status u1 u2 "Processing Facility" (some 3) "Washed and packed")
```

#### `transfer-product`
Transfer product custody to another principal.
```clarity
(transfer-product u1 'SP3...)
```

#### `add-supplier-attestation`
Verified suppliers attest to product quality (rating 1-10).
```clarity
(add-supplier-attestation u1 "Inspected and verified organic" u9)
```

#### `assign-to-restaurant`
Assign a delivered product to a restaurant.
```clarity
(assign-to-restaurant u1 'SP4...)
```

#### `deactivate-product`
Mark a product as inactive (consumed/expired).
```clarity
(deactivate-product u1)
```

### Read-Only Functions

#### `get-product`
Retrieve complete product information.
```clarity
(get-product u1)
```

#### `get-product-journey`
Get journey stage details for a product.
```clarity
(get-product-journey u1 u2)
```

#### `get-supplier`
Retrieve supplier information.
```clarity
(get-supplier 'SP2...)
```

#### `get-supplier-attestation`
Get a specific supplier's attestation for a product.
```clarity
(get-supplier-attestation u1 'SP2...)
```

#### `get-product-freshness`
Calculate freshness metrics (blocks elapsed since harvest).
```clarity
(get-product-freshness u1)
```

#### `get-product-supplier-count`
Get total number of suppliers who attested to a product.
```clarity
(get-product-supplier-count u1)
```

## 🔄 Product Journey Flow

1. **Harvested** (Status 1) - Farm registers product with origin
2. **Processed** (Status 2) - Processing facility updates status
3. **Distributed** (Status 3) - Distributor records receipt
4. **Delivered** (Status 4) - Restaurant receives product
5. **Assigned** - Product linked to restaurant for QR display

## 🚀 Usage Example

```clarity
;; 1. Supplier registers
(contract-call? .farm-to-plate register-supplier "Green Valley Farm" "Organic Farm" "USDA Organic")

;; 2. Owner verifies supplier
(contract-call? .farm-to-plate verify-supplier 'SP2...)

;; 3. Supplier registers product
(contract-call? .farm-to-plate register-product 
    "Heirloom Tomatoes" 
    "Green Valley, Sonoma County" 
    "Vegetables"
    "Greenhouse A"
    (some 18)
    "Vine-ripened, harvested at peak freshness")

;; 4. Processor updates status
(contract-call? .farm-to-plate update-product-status 
    u1 
    u2 
    "Valley Processing" 
    (some 4) 
    "Sorted and packaged")

;; 5. Supplier adds attestation
(contract-call? .farm-to-plate add-supplier-attestation 
    u1 
    "Certified organic, pesticide-free" 
    u10)

;; 6. Distributor updates status
(contract-call? .farm-to-plate update-product-status 
    u1 
    u3 
    "Regional Distribution Center" 
    (some 2) 
    "In cold storage")

;; 7. Restaurant receives and assigns
(contract-call? .farm-to-plate update-product-status 
    u1 
    u4 
    "Bella's Italian Restaurant" 
    (some 4) 
    "Ready for service")

(contract-call? .farm-to-plate assign-to-restaurant u1 'SP4...)

;; 8. Customer scans QR code (product ID: 1)
(contract-call? .farm-to-plate get-product u1)
(contract-call? .farm-to-plate get-product-freshness u1)
(contract-call? .farm-to-plate get-product-journey u1 u1)
```

## 📱 QR Code Integration

Restaurants generate QR codes containing the product ID. When scanned:
1. Customer's app queries blockchain with product ID
2. Contract returns complete journey history
3. Display shows origin, all handlers, timestamps, temperatures, and attestations
4. Freshness calculated from harvest block height

## 🛡️ Security Features

- Only verified suppliers can add attestations
- Product custody tracked at each transfer
- Status updates must follow sequential progression
- Contract owner has administrative oversight
- Immutable history prevents tampering

## 📊 Status Codes

- `1` - Harvested
- `2` - Processed
- `3` - Distributed
- `4` - Delivered

## 🧪 Testing

```bash
clarinet check
clarinet test
```

## 📄 License

MIT

## 🤝 Contributing

Contributions welcome! Please ensure all tests pass before submitting PRs.
