//
//  CoursePaymentHandler.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

import Foundation

struct CoursePaymentHandler {

    static func initiatePayment(
        course: Course,
        userId: UUID,
        authService: AuthService,
        paymentService: PaymentService,
        setOrderId: (String) -> Void,
        setPaymentURL: (URL) -> Void,
        onError: (String) -> Void
    ) async {

        guard let price = course.price else { return }
        guard let user = authService.currentUser else { return }

        if let order = await paymentService.createPaymentOrder(
            courseId: course.id,
            userId: userId,
            amount: price
        ) {
            setOrderId(order.orderId)

            if let url = paymentService.getPaymentURL(
                order: order,
                userEmail: user.email,
                userName: user.fullName
            ) {
                setPaymentURL(url)
            } else {
                onError("Failed to generate payment link")
            }
        } else {
            onError(paymentService.errorMessage ?? "Failed to create payment order")
        }
    }

    static func verifyPayment(
        orderId: String,
        paymentId: String,
        course: Course,
        userId: UUID,
        paymentService: PaymentService,
        onSuccess: () -> Void,
        onError: (String) -> Void
    ) async {

        let success = await paymentService.verifyPayment(
            orderId: orderId,
            paymentId: paymentId,
            courseId: course.id,
            userId: userId
        )

        if success {
            onSuccess()
        } else {
            onError(paymentService.errorMessage ?? "Payment verification failed")
        }
    }
}
