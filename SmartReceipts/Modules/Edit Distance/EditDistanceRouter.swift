//
//  EditDistanceRouter.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 01/06/2017.
//  Copyright © 2017 Will Baumann. All rights reserved.
//

import Foundation
import Viperit

class EditDistanceRouter: Router {
    func close() {
        _view.navigationController?.popViewController(animated: true)
    }
}

// MARK: - VIPER COMPONENTS API (Auto-generated code)
private extension EditDistanceRouter {
    var presenter: EditDistancePresenter {
        return _presenter as! EditDistancePresenter
    }
}
