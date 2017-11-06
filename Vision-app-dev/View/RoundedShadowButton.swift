//
//  RoundedShadowButton.swift
//  Vision-app-dev
//
//  Created by Jacob Ahlberg on 2017-11-03.
//  Copyright © 2017 Jacob Ahlberg. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedShadowButton: UIButton {

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        roundedShadow()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        roundedShadow()
    }
    
    func roundedShadow() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = self.frame.height / 2
    }

}
