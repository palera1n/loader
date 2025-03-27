//
//  LRStageGroupltemView.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import UIKit

class LRStageGroupItemView: UIView {
    var status: StepStatus {
        didSet {
            updateIndicatorImage()
        }
    }
	
	private let _timerManager = TimerManager()
    
    private let _name: String
    private let _padding: CGFloat
	#if os(iOS)
	private let _indicatorSize: CGFloat = 20
	#else
	private let _indicatorSize: CGFloat = 50
	#endif
    
    private let _indicator = UIView()
	private let _animatedIndicator = LRStagedLoadingIndicator()
    
    private lazy var _separator: UIView = {
        let separator = UIView()
		#if os(iOS)
        separator.backgroundColor = .systemGray4
		#else
		separator.backgroundColor = .separator
		#endif
        return separator
    }()
        
    private let _statusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let _label: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        return nameLabel
    }()
	
	private let _timeLabel: UILabel = {
		let nameLabel = UILabel()
		nameLabel.font = .preferredFont(forTextStyle: .subheadline)
		nameLabel.textColor = .secondaryLabel
		nameLabel.adjustsFontForContentSizeCategory = true
		return nameLabel
	}()
    
    init(_ name: String, padding: CGFloat, status: StepStatus) {
        self._name = name
        self._padding = padding
        self.status = status
        super.init(frame: .zero)
        
        _setup()
        updateIndicatorImage()
    }

	required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _setup() {
        addSubview(_separator)
        _separator.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(_indicator)
        _indicator.translatesAutoresizingMaskIntoConstraints = false
        
        _indicator.addSubview(_statusImageView)
        _statusImageView.translatesAutoresizingMaskIntoConstraints = false
		
		_indicator.addSubview(_animatedIndicator)
		_animatedIndicator.translatesAutoresizingMaskIntoConstraints = false
		_animatedIndicator.layer.opacity = 0
        
        addSubview(_label)
        _label.translatesAutoresizingMaskIntoConstraints = false
        _label.text = _name
		
		addSubview(_timeLabel)
		_timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            _separator.topAnchor.constraint(equalTo: self.topAnchor),
            _separator.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            _separator.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            _separator.heightAnchor.constraint(equalToConstant: 1),
            
            _indicator.heightAnchor.constraint(equalToConstant: _indicatorSize),
            _indicator.widthAnchor.constraint(equalToConstant: _indicatorSize),
            
            _indicator.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            _indicator.topAnchor.constraint(equalTo: self.topAnchor, constant: _padding),
            _indicator.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            _statusImageView.topAnchor.constraint(equalTo: _indicator.topAnchor),
            _statusImageView.leadingAnchor.constraint(equalTo: _indicator.leadingAnchor),
            _statusImageView.trailingAnchor.constraint(equalTo: _indicator.trailingAnchor),
            _statusImageView.bottomAnchor.constraint(equalTo: _indicator.bottomAnchor),
			
			_animatedIndicator.topAnchor.constraint(equalTo: _indicator.topAnchor, constant: 2),
			_animatedIndicator.leadingAnchor.constraint(equalTo: _indicator.leadingAnchor, constant: 2),
			_animatedIndicator.trailingAnchor.constraint(equalTo: _indicator.trailingAnchor, constant: -2),
			_animatedIndicator.bottomAnchor.constraint(equalTo: _indicator.bottomAnchor, constant: -2),
            
            _label.leadingAnchor.constraint(equalTo: _indicator.trailingAnchor, constant: _padding),
            _label.centerYAnchor.constraint(equalTo: _indicator.centerYAnchor),
			
			_timeLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -_padding),
			_timeLabel.centerYAnchor.constraint(equalTo: _label.centerYAnchor)
        ])
    }
    
    private func updateIndicatorImage() {
        let isInitialSetup = _statusImageView.image == nil
        
        switch status {
        case .inProgress:
            _handleInProgressState()
        case .completed, .failed, .pending:
            _handleStandardState()
        }
        
        if !isInitialSetup {
            _animateStatusChange()
        }
    }

    private func _handleInProgressState() {
		 _timerManager.startTimer(timeInterval: 2.0)
		
        UIView.animate(withDuration: 0.2) {
            self._statusImageView.alpha = 0
            self._animatedIndicator.alpha = 1
        }
    }

    private func _handleStandardState() {
        _statusImageView.image = UIImage(systemName: status.systemImageName)
        _statusImageView.tintColor = status.tintColor
		
		if let elapsed = _timerManager.invalidateTimerWithReturningSeconds() {
			_timeLabel.text = elapsed
		}
        
        UIView.animate(withDuration: 0.4,
                      delay: 0,
                      usingSpringWithDamping: 0.7,
                      initialSpringVelocity: 0.5,
                      options: [.curveEaseInOut],
                      animations: {
            self._statusImageView.alpha = 1
            self._animatedIndicator.alpha = 0
        })
    }

    private func _animateStatusChange() {
        if status != .inProgress {
            let duration = 0.5
            
            UIView.animate(withDuration: duration * 0.6,
                         delay: 0,
                         usingSpringWithDamping: 0.6,
                         initialSpringVelocity: 0.8,
                         options: [.curveEaseOut],
                         animations: {
                self._statusImageView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
            }, completion: { _ in
                UIView.animate(withDuration: duration * 0.7,
                             delay: 0,
                             usingSpringWithDamping: 0.7, 
                             initialSpringVelocity: 0.2,
                             options: [.curveEaseOut],
                             animations: {
                    self._statusImageView.transform = .identity
                })
            })
            
            let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.values = [-0.05, 0.05, -0.025, 0.025, 0]
            rotationAnimation.duration = duration
            rotationAnimation.isAdditive = true
            _statusImageView.layer.add(rotationAnimation, forKey: "subtleRotation")
        }
    }
}
