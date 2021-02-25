//
// Created by BingBong on 2021/01/05.
//

import Foundation
import WebKit
import RxBus
import RxSwift

public class IamportSdk {

    let viewModel = MainViewModel()
    let naviController: UINavigationController

    var chaiApproveCallBack: ((IamPortApprove) -> Void)? // 차이 결제 확인 콜백
    var resultCallBack: ((IamPortResponse?) -> Void)? // 결제 결과 콜백

    var disposeBag = DisposeBag()

    public init(_ naviController: UINavigationController) {
        self.naviController = naviController
    }

    // 뷰모델 데이터 클리어
    func clearData() {
        print("IamportSdk clearData!")
//        updatePolling(false)
//        controlForegroundService(false)

        viewModel.clear()
        EventBus.shared.clearRelay.accept(())
        disposeBag = DisposeBag()
    }

    private func sdkFinish(_ iamportResponse: IamPortResponse?) {
        print("I'mport SDK 에서 종료입니다")
        clearData()
        resultCallBack?(iamportResponse)
    }

    internal func initStart(payment: Payment, approveCallback: ((IamPortApprove) -> Void)?, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("initStart Payment")
//        clearData()

        chaiApproveCallBack = approveCallback
        resultCallBack = paymentResultCallback

        subscribe(payment) // 관찰할 옵저버블
    }

    internal func initStart(payment: Payment, certificationResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("initStart Certification")
//        clearData()

        resultCallBack = certificationResultCallback

        subscribeCertification(payment) // 관찰할 옵저버블
    }

    func postReceivedURL(_ url: URL) {
        dlog("외부앱 종료 후 전달 받음 => \(url)")
        RxBus.shared.post(event: EventBus.WebViewEvents.ReceivedAppDelegateURL(url: url))
    }

    private func subscribe(_ payment: Payment) {
        // 결제결과 옵저빙
        EventBus.shared.impResponseBus.subscribe { [weak self] iamportResponse in
            self?.sdkFinish(iamportResponse)
        }.disposed(by: disposeBag)

        // TODO subscribe 결제결과

        // subscribe 웹뷰열기
        EventBus.shared.paymentBus.subscribe { [weak self] event in
            guard let el = event.element, let pay = el else {
                print("Error paymentBus is nil")
                return
            }

            self?.openWebViewController(pay)
        }.disposed(by: disposeBag)

        // subscribe 차이앱열기
        RxBus.shared.asObservable(event: EventBus.MainEvents.ChaiUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found PaymentEvent")
                return
            }

            self?.openApp(payment, appAddress: el.appAddress)

        }.disposed(by: disposeBag)

        // TODO subscribe 폴링여부

        // 차이 결제 상태 approve 처리
        RxBus.shared.asObservable(event: EventBus.MainEvents.AskApproveFromChai.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ChaiApprove")
                return
            }

            self?.askApproveFromChai(approve: el.approve)

        }.disposed(by: disposeBag)

        // 결제요청
        requestPayment(payment)
    }

    private func subscribeCertification(_ payment: Payment) {

        // 결제결과 옵저빙
        EventBus.shared.impResponseBus.subscribe { [weak self] iamportResponse in
            self?.sdkFinish(iamportResponse)
        }.disposed(by: disposeBag)

        // subscribe 웹뷰열기
        EventBus.shared.paymentBus.subscribe { [weak self] event in
            guard let el = event.element, let pay = el else {
                print("Error paymentBus is nil")
                return
            }

            self?.openWebViewController(pay)
        }.disposed(by: disposeBag)

        // 본인인증 요청
        requestCertification(payment)
    }


    private func openApp(_ payment: Payment, appAddress: URL) {
        let result = Utils.openApp(appAddress) // 앱 열기
        // TODO openApp result = false 일 떄, 이미 chai strategy 가 동작할 시나리오
        // 취소? 타임아웃 연장? 그대로 진행? ... 등
        // 어차피 앱 재설치시, 다시 차이 결제 페이지로 진입할 방법이 없음
        if (!result) {
            if let scheme = appAddress.scheme,
               let urlString = AppScheme.getAppStoreUrl(scheme: scheme),
               let url = URL(string: urlString) {
                Utils.openApp(url) // 앱스토어 이동
            } else {
                sdkFinish(IamPortResponse.makeFail(payment: payment, msg: "지원하지 않는 App Scheme\(String(describing: appAddress.scheme)) 입니다"))
            }
        }
    }

    // approveCallBack 이 있으면, 머천트의 컨펌을 받음
    private func askApproveFromChai(approve: IamPortApprove) {
        if let cb = chaiApproveCallBack {
            cb(approve)
        } else {
            requestApprovePayments(approve: approve) // 없으면 바로 차이 최종 결제 요청
        }
    }

    // 차이 최종 결제 요청
    public func requestApprovePayments(approve: IamPortApprove) {
        viewModel.requestApprovePayments(approve: approve)
    }

    private func requestPayment(_ payment: Payment) {

        Payment.validator(payment) { valid, desc in
            print("Payment validator valid :: \(valid), valid :: \(desc)")
            if (!valid) {
                self.sdkFinish(IamPortResponse.makeFail(payment: payment, msg: desc))
                return
            }
        }

        if (!Utils.isInternetAvailable()) {
            sdkFinish(IamPortResponse.makeFail(payment: payment, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.judgePayment(payment)
    }

    private func requestCertification(_ payment: Payment) {

        if (!Utils.isInternetAvailable()) {
            sdkFinish(IamPortResponse.makeFail(payment: payment, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.judgePayment(payment)
    }

    // 웹뷰 컨트롤러 열기 및 데이터 전달
    private func openWebViewController(_ payment: Payment) {
        DispatchQueue.main.async { [weak self] in
            EventBus.shared.webViewPaymentRelay.accept(payment)
            self?.naviController.pushViewController(WebViewController(), animated: true)
//            self?.naviController.present(WebViewController(), animated: true)
            dlog("check navigationController :: \(String(describing: self?.naviController))")
        }
    }

}