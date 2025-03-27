//
//  LRStageGroupCell.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import UIKit

class LRStageGroupCell: UICollectionViewCell {
	var step: StepGroup? {
		didSet {
			_updateContent()
		}
	}

	private var _items: [LRStageGroupItemView] = []
	
	private var _closedConstraint: NSLayoutConstraint?
	private var _openConstraint: NSLayoutConstraint?
	private var _bottomMostLabel: UIView?
	
	#if os(iOS)
	private let _padding: CGFloat = 14
	#else
	private let _padding: CGFloat = 30
	#endif
	private let _cornerRadius: CGFloat = 14

	private let _nameLabel: UILabel = {
		let nameLabel = UILabel()
		nameLabel.font = .systemFont(
			ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize,
			weight: .semibold
		)
		return nameLabel
	}()
	
	private let _disclosureIndicator: UIImageView = {
		let disclosureIndicator = UIImageView()
		disclosureIndicator.image = UIImage(systemName: "chevron.down")
		disclosureIndicator.contentMode = .scaleAspectFit
		#if os(tvOS)
		disclosureIndicator.tintColor = .clear
		#endif
		disclosureIndicator.preferredSymbolConfiguration = .init(textStyle: .headline, scale: .medium)
		return disclosureIndicator
	}()
	
	private lazy var _labelStack: UIStackView = {
		let labelStack = UIStackView(arrangedSubviews: [_nameLabel])
		labelStack.axis = .vertical
		labelStack.spacing = _padding
		return labelStack
	}()
		
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	override var isSelected: Bool {
		didSet {
			_updateAppearance()
		}
	}
	
	required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
		
	private func setup() {
		#if os(iOS)
		backgroundColor = .systemGray5
		#else
		backgroundColor = .systemGray.withAlphaComponent(0.1)
		#endif
		clipsToBounds = true
		
		layer.cornerRadius = _cornerRadius
		layer.cornerCurve = .continuous
		
		contentView.translatesAutoresizingMaskIntoConstraints = false
		
		contentView.addSubview(_labelStack)
		_labelStack.translatesAutoresizingMaskIntoConstraints = false
		
		contentView.addSubview(_disclosureIndicator)
		_disclosureIndicator.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			contentView.topAnchor.constraint(equalTo: topAnchor),
			contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
			contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
			contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
			
			_labelStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: _padding),
			_labelStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: _padding),
			_labelStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			
			_disclosureIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -_padding),
			_disclosureIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: _padding),
			
		])
		
		_closedConstraint = _nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -_padding)
		_closedConstraint?.priority = .defaultLow
		
		_openConstraint = _nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -_padding)
		_openConstraint?.priority = .defaultLow
		
		_updateAppearance()
	}
	
	private func _updateContent() {
		guard let step = step else { return }
		
		for view in _labelStack.arrangedSubviews where view != _nameLabel {
			_labelStack.removeArrangedSubview(view)
			view.removeFromSuperview()
		}
		
		_items.removeAll()
		
		_nameLabel.text = step.name
				
		for item in step.items {
			let view = LRStageGroupItemView(item.name, padding: _padding, status: item.status)

			_items.append(view)
			_labelStack.addArrangedSubview(view)
		}
		
		let lastLabel = _items.last ?? _nameLabel
		_bottomMostLabel = lastLabel
		_openConstraint = lastLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -_padding)
		_openConstraint?.priority = .defaultLow
		
		_updateAppearance()
	}
	
	/// Updates the views to reflect changes in selection
	private func _updateAppearance() {
		_closedConstraint?.isActive = !isSelected
		_openConstraint?.isActive = isSelected
		
		UIView.animate(withDuration: 0.3) {
			let upsideDown = CGAffineTransform(rotationAngle: .pi * 0.999)
			self._disclosureIndicator.transform = self.isSelected ? upsideDown : .identity
		}
	}
}

// MARK: - Item Updates
extension LRStageGroupCell {
    /// Updates a specific item view's status without rebuilding the entire cell
    /// - Parameters:
    ///   - id: The UUID of the item to update
    ///   - newStatus: The new status to apply
    func updateItemStatus(withId id: UUID, to newStatus: StepStatus) {
        // 1. Update the data model
        guard var step = step else { return }
		
		#if os(iOS)
		let generator = UIImpactFeedbackGenerator(style: .soft)
		generator.prepare()
		#endif
        
        // Find the item and update it
        for i in 0..<step.items.count {
            if step.items[i].id == id {
				step.items[i].status = newStatus
                
                // 2. If the corresponding view exists, update it
                if i < _items.count {
                    UIView.transition(with: _items[i], duration: 0.2, options: .transitionCrossDissolve, animations: {
                        self._items[i].status = newStatus
					}, completion: { _ in
						#if os(iOS)
						if newStatus == .completed {
							
							generator.impactOccurred()
						}
						#endif
					})
					
                }
                break
            }
        }
    }
    
    /// Updates a specific item view's status by name without rebuilding the entire cell
    /// - Parameters:
    ///   - name: The name of the item to update
    ///   - newStatus: The new status to apply
    func updateItemStatus(withName name: String, to newStatus: StepStatus) {
        // 1. Update the data model
        guard var step = step else { return }
		#if os(iOS)
		let generator = UIImpactFeedbackGenerator(style: .soft)
		generator.prepare()
		#endif
        
        // Find the item by name and update it
        for i in 0..<step.items.count {
            if step.items[i].name == name {
				step.items[i].status = newStatus
                
                // 2. If the corresponding view exists, update it
                if i < _items.count {
                    UIView.transition(with: _items[i], duration: 0.2, options: .transitionCrossDissolve, animations: {
                        self._items[i].status = newStatus
					}, completion: { _ in
						#if os(iOS)
						if newStatus == .completed {
							
							generator.impactOccurred()
						}
						#endif
					})
                }
                break
            }
        }
    }
}
