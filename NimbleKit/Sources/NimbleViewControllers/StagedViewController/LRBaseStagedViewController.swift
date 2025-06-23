//
//  LRBaseStagedViewController.swift
//  Loader
//
//  Created by samara on 19.03.2025.
//

import UIKit

// MARK: - Class
open class LRBaseStagedViewController: UIViewController {
	typealias StepDataSourceSection = Int
	typealias StepDataSource = UICollectionViewDiffableDataSource<StepDataSourceSection, StepGroup>
	typealias StepDataSourceSnapshot = NSDiffableDataSourceSnapshot<StepDataSourceSection, StepGroup>
	
	private var _dataSource: StepDataSource?
	
	lazy var collectionView = UICollectionView(
		frame: .zero,
		collectionViewLayout: _createLayout()
	)
	
	private let _footerLabel: UILabel = {
		let label = UILabel()
		label.font = .preferredFont(forTextStyle: .subheadline)
		label.textColor = .secondaryLabel
		label.adjustsFontForContentSizeCategory = true
		label.numberOfLines = 0
		label.textAlignment = .center
		return label
	}()
	
	public var steps: [StepGroup] = []
	public var footerString: String = ""
	
	public init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	open override func viewDidLoad() {
        super.viewDidLoad()
		self.setupView()
		_setupCollectionView()
		_setupDataSource()
		collectionView.delegate = self
		self.start()
    }
	
	open func setupView() {}
	open func start() {}
	
	private func _createLayout() -> UICollectionViewLayout {
		let itemSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1.0),
			heightDimension: .estimated(50)
		)
		
		let item = NSCollectionLayoutItem(layoutSize: itemSize)
		let group = NSCollectionLayoutGroup.horizontal(
			layoutSize: itemSize,
			subitems: [item]
		)
		
		let padding: CGFloat = 12
		
		let section = NSCollectionLayoutSection(group: group)
		section.interGroupSpacing = padding
		section.contentInsets = .init(top: padding, leading: padding, bottom: padding, trailing: padding)
		
		return UICollectionViewCompositionalLayout(section: section)
	}
	
	private func _setupCollectionView() {
		#if os(iOS)
		collectionView.backgroundColor = .systemBackground
		#endif
		collectionView.register(
			LRStageGroupCell.self,
			forCellWithReuseIdentifier: String(describing: LRStageGroupCell.self)
		)
		
		view.addSubview(collectionView)
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		
		collectionView.addSubview(_footerLabel)
		_footerLabel.translatesAutoresizingMaskIntoConstraints = false
		_footerLabel.text = footerString
		
		NSLayoutConstraint.activate([
			collectionView.topAnchor.constraint(equalTo: view.topAnchor),
			collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			
			_footerLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
			_footerLabel.bottomAnchor.constraint(equalTo: collectionView.safeAreaLayoutGuide.bottomAnchor, constant: -32),
			_footerLabel.widthAnchor.constraint(equalTo: collectionView.widthAnchor, multiplier: 0.7)
		])
	}
	
	private func _setupDataSource() {
		_dataSource = StepDataSource(
			collectionView: collectionView
		) { (collectionView, indexPath, step) -> UICollectionViewCell? in
			guard let cell = collectionView.dequeueReusableCell(
				withReuseIdentifier: String(describing: LRStageGroupCell.self),
				for: indexPath
			) as? LRStageGroupCell else {
				fatalError("Could not cast cell as \(LRStageGroupCell.self)")
			}
			cell.step = step
			return cell
		}
		collectionView.dataSource = _dataSource
		
		var snapshot = StepDataSourceSnapshot()
		snapshot.appendSections([0])
		snapshot.appendItems(steps)
		_dataSource?.apply(snapshot)
	}
	
	public func updateStepItemStatus(_ section: String, item: String, with status: StepStatus) {
		guard
			let stepIndex = steps.firstIndex(where: { $0.name == section }),
			let itemIndex = steps[stepIndex].items.firstIndex(where: { $0.name == item })
		else {
			print("Couldn't find step with name '\(section)' or item with name '\(item)'")
			return
		}
		
		let itemId = steps[stepIndex].items[itemIndex].id
		
		steps[stepIndex].items[itemIndex].status = status
		
		let indexPath = IndexPath(item: stepIndex, section: 0)
		guard let cell = collectionView.cellForItem(at: indexPath) as? LRStageGroupCell else {
			print("Cell not visible for step '\(section)'")
			return
		}
		
		cell.updateItemStatus(withId: itemId, to: status)
	}
	
	public func updateStepItemStatusForName(named item: String, with status: StepStatus) {
		for (stepIndex, step) in steps.enumerated() {
			if let itemIndex = step.items.firstIndex(where: { $0.name == item }) {
				steps[stepIndex].items[itemIndex].status = status
				
				let indexPath = IndexPath(item: stepIndex, section: 0)
				guard let cell = collectionView.cellForItem(at: indexPath) as? LRStageGroupCell else {
					continue
				}
				
				cell.updateItemStatus(withName: item, to: status)
				return
			}
		}
		
		print("Couldn't find any step item with name '\(item)'")
	}
}

// MARK: - Class extension: collectionview
extension LRBaseStagedViewController: UICollectionViewDelegate {
	public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		selectCollectionViewCell(for: indexPath.row)
		return false
	}
	
	public func selectCollectionViewCell(for row: Int) {
		guard let dataSource = _dataSource else { return }
		
		let section = IndexPath(row: row, section: 0)
		
		if collectionView.indexPathsForSelectedItems?.contains(section) ?? false {
			collectionView.deselectItem(at: section, animated: true)
		} else {
			collectionView.selectItem(at: section, animated: true, scrollPosition: [])
		}
		
		UIView.animate(withDuration: 0.6,
					   delay: 0,
					   usingSpringWithDamping: 0.65,
					   initialSpringVelocity: 0.5,
					   options: [.curveEaseOut],
					   animations: {
			dataSource.refresh()
		})
	}
}
