import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;

  final Function(String paymentId) onPaymentSuccess;
  final Function(String? errorMessage) onPaymentFailed;

  PaymentService({
    required this.onPaymentSuccess,
    required this.onPaymentFailed,
  }) {
    _razorpay = Razorpay();

    // EVENT LISTENERS
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // 🔥 OPEN CHECKOUT POPUP
  void openCheckout({
    required int amount,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) {
    var options = {
      'key': 'rzp_test_Rl3ZPS66sg8atd', // ⬅ Replace with live key or env variable
      'amount': amount, // Razorpay accepts amount in paise
      'name': "BMT99",
      'description': "Order Payment",
      'currency': "INR",

      // Customer details
      'prefill': {
        'name': userName,
        'email': userEmail,
        'contact': userPhone,
      },

      // Theme
      'theme': {
        "color": "#0A9C0A",
      }
    };

    try {
      _razorpay.open(options);
      print("🔔 Razorpay Checkout Opened");
    } catch (e) {
      print("❌ Razorpay open error: $e");
      onPaymentFailed(e.toString());
    }
  }

  // 🎉 SUCCESS CALLBACK
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("🎉 PAYMENT SUCCESS: ${response.paymentId}");
    onPaymentSuccess(response.paymentId!);
  }

  // ❌ FAILURE CALLBACK
  void _handlePaymentError(PaymentFailureResponse response) {
    print("❌ PAYMENT FAILED: ${response.message}");
    onPaymentFailed(response.message);
  }

  // 💼 EXTERNAL WALLET
  void _handleExternalWallet(ExternalWalletResponse response) {
    print("📦 External Wallet Selected: ${response.walletName}");
  }

  // 🔥 MUST DISPOSE
  void dispose() {
    _razorpay.clear();
  }
}
