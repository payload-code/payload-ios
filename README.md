# Payload iOS Library

An iOS library for integrating [Payload](https://payload.co)

## Installation

### Cocoapod Installation

- Add  `pod 'Payload'` to your Podfile

- Run `pod install`

## Get Started

Once you've included the Payload iOS library into you project,
import the library into your view.

```swift
import Payload
````

### API Authentication

To authenticate with the Payload API, you'll need a live or test API key. API
keys are accessible from within the Payload dashbvoard.

```swift
import Payload

Payload.api_key = "client_key_3bW9JMZtPVDOfFNzwRdfE"
```

## Checkout

Use `Payload.checkout` for integrating a simple checkout modal into your app.

```swift
Payload.Checkout(Payload.Payment([
    "amount": 10.0
]), delegate: self)
```

## Interact with the API

### Create an Object

Interfacing with the Payload API is done primarily through Payload Objects. Below is an example of creating a payment using the Payload.Payment object.

```swift
// Create a Payment
Payload.create(Payload.Payment([
    "amount": 10.0,
    "payment_methid_id": "pm_u7NDGPfjBc4uwChD"
]), {(obj: Any) in
    let payment = (obj as? Payload.Transaction)!
}, {(error: Payload.PayloadError) in
})
```

### Void a Payment

```swift
payment.update(["status": "voided"], completion, error_cb: error_cb)
```

### Select Customers

```swift
Payload.all(Payload.Customer.filter_by([
    "email": "matt.perez@example.com"
]), {(obj: Any) in
    let custs = obj as! [Payload.Customer]
    /* Do something with response */
})
```

### Get a Specific Customer

```swift
Payload.get(Payload.Customer(["id: cust_id])), {(obj: Any) in
    let cust = obj as! Payload.Customer
    /* Do something with response */
})
```

### Handle Request Errors

```swift
// Create a Payment
Payload.create(Payload.Payment([
    "email": "matt perez@example.com",
    "name": "Matt Perez"
]), {(obj: Any) in
    let cust = (obj as? Payload.Customer)!
}, {(error: Payload.PayloadError) in
 handleError(error);
})
```


## Documentation

To get further information on Payload's iOS library and API capabilities,
visit the unabridged [Payload Documentation](https://docs.payload.co/).
