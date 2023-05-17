//
//  CustomTableViewCell.swift
//  palera1nLoader
//
//  Created by samara on 4/22/23.
//

import UIKit

class UserModal {
    var titleImg: UIImage?
    var titleLabel: String?
    var subTitleLabel: String?
    
    init(titleImg: UIImage, titleLabel: String, subTitleLabel: String) {
        self.titleImg = titleImg
        self.titleLabel = titleLabel
        self.subTitleLabel = subTitleLabel
    }
}

class CustomTableViewCell: UITableViewCell {
    
    let backView: UIView = {
        let view = UIView()
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    
    let titleImg: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = UIColor.label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
        setupConstraints()
    }
    
    func setupViews() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        backView.layer.cornerRadius = 15
        backView.clipsToBounds = true
        titleImg.layer.cornerRadius = 15
        titleImg.layer.cornerCurve = .continuous
        addSubview(backView)
        backView.addSubview(titleImg)
        backView.addSubview(titleLabel)
        backView.addSubview(subTitleLabel)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            backView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            backView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            backView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            
            titleImg.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            titleImg.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            titleImg.widthAnchor.constraint(equalToConstant: 60),
            titleImg.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 23),
            titleLabel.leadingAnchor.constraint(equalTo: titleImg.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            
            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subTitleLabel.leadingAnchor.constraint(equalTo: titleImg.trailingAnchor, constant: 16),
            subTitleLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            subTitleLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -24)
        ])
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.4) {
            if highlighted {
                self.backView.backgroundColor = UIColor.systemGray4
            } else {
                // Set the background color to the original blur effect
                self.backView.backgroundColor = UIColor.clear
            }
        }
    }


    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        selectionStyle = .none
    }
    
    func configure(with user: UserModal) {
        titleImg.image = user.titleImg
        titleLabel.text = user.titleLabel
        subTitleLabel.text = user.subTitleLabel
    }
}

class BlurredBackgroundView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBlurEffect()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBlurEffect()
    }
    
    private func setupBlurEffect() {
        // Create a blur effect
        let blurEffect = UIBlurEffect(style: .regular)
        
        // Create a blur effect view
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add the blur effect view as a subview
        addSubview(blurEffectView)
    }
}
