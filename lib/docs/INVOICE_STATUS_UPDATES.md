# Invoice Status Updates Implementation Guide

This document explains how the real-time invoice status update system works in the Spreadlee Flutter frontend.

## Overview

The invoice status update system provides real-time synchronization between the backend invoice status and the frontend UI. When an invoice status changes on the backend (e.g., from "Unpaid" to "Paid"), all connected clients receive the update immediately through WebSocket events.

## Architecture

### Backend Events
The backend emits the following events when invoice status changes:
- `invoice_updated` - Primary event for invoice status changes
- `message_sent` - Contains updated invoice data in message invoiceData
- `new_message` - Contains updated invoice data in new messages

### Frontend Services

#### 1. InvoiceUpdateService
Handles WebSocket connections and event listening for invoice updates.

**Key Features:**
- Listens to `invoice_updated`, `message_sent`, and `new_message` events
- Joins relevant chat rooms and company rooms
- Provides streams for different types of updates
- Handles chat-specific and invoice-specific listeners

**Usage:**
```dart
final invoiceUpdateService = InvoiceUpdateService();
await invoiceUpdateService.initialize(
  baseUrl: Constants.socketBaseUrl,
  token: Constants.token,
  userId: Constants.userId,
  userRole: Constants.role,
);

// Listen for updates
invoiceUpdateService.invoiceUpdateStream.listen((event) {
  // Handle invoice update
});
```

#### 2. InvoiceStatusSyncService
Synchronizes invoice status between frontend and backend.

**Key Features:**
- Tracks invoice statuses across the app
- Maps backend statuses to frontend statuses
- Provides status change notifications
- Maintains status history

**Usage:**
```dart
final statusService = InvoiceStatusSyncService();
await statusService.initialize();

// Get current status
String? status = statusService.getInvoiceStatus(invoiceId);

// Check if paid
bool isPaid = statusService.isInvoicePaid(invoiceId);

// Listen for status changes
statusService.statusUpdateStream.listen((update) {
  // Handle status change
});
```

### Widgets

#### 1. InvoiceStatusIndicator
Displays real-time invoice status with animations.

**Features:**
- Real-time status updates
- Smooth animations on status change
- Customizable size and appearance
- Optional text display

**Usage:**
```dart
InvoiceStatusIndicator(
  invoiceId: 'invoice_123',
  initialStatus: 'unpaid',
  showText: true,
  showAnimation: true,
  onStatusChanged: () {
    // Handle status change
  },
)
```

#### 2. InvoiceStatusBadge
Compact status indicator for lists and cards.

**Usage:**
```dart
InvoiceStatusBadge(
  invoiceId: 'invoice_123',
  initialStatus: 'unpaid',
  size: 16.0,
)
```

#### 3. InvoiceStatusText
Text widget that updates in real-time.

**Usage:**
```dart
InvoiceStatusText(
  invoiceId: 'invoice_123',
  initialStatus: 'unpaid',
  style: TextStyle(fontWeight: FontWeight.bold),
)
```

## Status Mapping

### Backend to Frontend Status Mapping
- `Paid` → `paid`
- `Unpaid` → `unpaid`
- `Expired` → `expired`
- `under review` → `pending`

### Payment Status Mapping
- `Completed` → `paid`
- `Pending` → `pending`
- `Failed` → `unpaid`

## Integration Examples

### 1. Message Invoice Widget Integration

```dart
class MessageInvoiceWidget extends StatefulWidget {
  // ... existing code ...
  
  @override
  void initState() {
    super.initState();
    _initializeInvoiceUpdateService();
  }

  Future<void> _initializeInvoiceUpdateService() async {
    await _invoiceUpdateService.initialize(
      baseUrl: Constants.socketBaseUrl,
      token: Constants.token,
      userId: Constants.userId,
      userRole: Constants.role,
    );

    _setupInvoiceUpdateListeners();
    _joinAllRelevantRooms();
  }

  void _setupInvoiceUpdateListeners() {
    // Listen for general invoice updates
    _invoiceUpdateSubscription = _invoiceUpdateService.invoiceUpdateStream.listen(
      (event) => _handleInvoiceUpdate(event),
    );

    // Add chat-specific listener
    if (widget.chatId != null) {
      _invoiceUpdateService.addChatListener(widget.chatId!, _handleChatSpecificUpdate);
    }

    // Add invoice-specific listener
    if (widget.message.messageInvoiceRef is String) {
      final invoiceId = widget.message.messageInvoiceRef as String;
      _invoiceUpdateService.addInvoiceListener(invoiceId, _handleInvoiceSpecificUpdate);
    }
  }

  void _handleInvoiceUpdate(InvoiceUpdateEvent event) {
    if (_isRelevantInvoiceUpdate(event)) {
      _updateInvoiceData(event.invoice);
    }
  }

  void _handleChatSpecificUpdate(InvoiceUpdateEvent event) {
    if (_isRelevantInvoiceUpdate(event)) {
      _updateInvoiceData(event.invoice);
    }
  }
}
```

### 2. Invoice List Integration

```dart
class InvoiceListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return ListTile(
          leading: InvoiceStatusBadge(
            invoiceId: invoice.id,
            initialStatus: invoice.invoiceStatus,
          ),
          title: Text('Invoice ${invoice.invoice_id}'),
          subtitle: InvoiceStatusText(
            invoiceId: invoice.id,
            initialStatus: invoice.invoiceStatus,
          ),
        );
      },
    );
  }
}
```

### 3. Invoice Details Integration

```dart
class InvoiceDetailsWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Invoice ${invoice.invoice_id}')),
                InvoiceStatusIndicator(
                  invoiceId: invoice.id,
                  initialStatus: invoice.invoiceStatus,
                  showText: true,
                  showAnimation: true,
                ),
              ],
            ),
            // ... other invoice details ...
          ],
        ),
      ),
    );
  }
}
```

## Event Flow

1. **Backend Status Change**: Invoice status changes in the database
2. **Backend Event Emission**: Backend emits `invoice_updated` event
3. **WebSocket Delivery**: Event is delivered to all connected clients
4. **Frontend Processing**: InvoiceUpdateService receives the event
5. **Status Synchronization**: InvoiceStatusSyncService updates the status
6. **UI Update**: Widgets automatically update to reflect new status
7. **Animation**: Status indicators animate to show the change

## Error Handling

The system includes comprehensive error handling:

- **Connection Errors**: Automatic reconnection with exponential backoff
- **Event Parsing Errors**: Graceful handling of malformed events
- **Status Mapping Errors**: Fallback to original status values
- **Widget Errors**: Safe error boundaries prevent crashes

## Performance Considerations

- **Stream Management**: Proper disposal of streams to prevent memory leaks
- **Event Filtering**: Only relevant events are processed
- **Animation Optimization**: Animations are disabled when not visible
- **Status Caching**: Statuses are cached to reduce redundant updates

## Testing

To test the invoice status update system:

1. **Start Multiple Clients**: Open the app on multiple devices/browsers
2. **Create Invoice**: Create an invoice in one client
3. **Change Status**: Update the invoice status in the backend
4. **Verify Updates**: Check that all clients receive the update
5. **Test Animations**: Verify that status indicators animate properly

## Troubleshooting

### Common Issues

1. **No Updates Received**
   - Check WebSocket connection status
   - Verify room membership
   - Check event listener setup

2. **Status Not Updating**
   - Verify invoice ID matching
   - Check status mapping logic
   - Ensure proper event handling

3. **Animation Issues**
   - Check animation controller initialization
   - Verify widget lifecycle management
   - Ensure proper disposal

### Debug Logging

Enable debug logging to troubleshoot issues:

```dart
if (kDebugMode) {
  print('InvoiceUpdateService: Received event: $event');
  print('InvoiceStatusSyncService: Status updated: $status');
}
```

## Future Enhancements

- **Status History**: Track complete status change history
- **Push Notifications**: Send notifications for status changes
- **Offline Support**: Cache statuses for offline viewing
- **Batch Updates**: Handle multiple status updates efficiently
