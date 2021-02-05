//
// Created by BingBong on 2021/01/05.
//

import RxBus
import RxSwift
import Foundation

internal class WebViewModel {

    let repository = StrategyRepository() // sTODO dependency inject

    func clear() {
        repository.clear()
    }

    /**
     * 뱅크페이 결과 처리
     */
    func processBankPayPayment(_ payment : Payment, _ url : URL) {
        repository.processBankPayPayment(payment, url)
    }

    /**
     * 결제 요청
     */
    func requestPayment(payment: Payment) {
        #if DEBUG
        print("뷰모델에 요청했니")
        #endif
        DispatchQueue.main.async {
            self.repository.getWebViewStrategy(payment).doWork(payment)
        }
    }
}