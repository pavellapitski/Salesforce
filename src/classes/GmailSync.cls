global class GmailSync implements Messaging.InboundEmailHandler {
    // DEPRECATED
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        return new Messaging.InboundEmailresult();
    }
}