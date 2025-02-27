//
//  BeatiOSOutlineView.swift
//  Beat iOS
//
//  Created by Lauri-Matti Parppei on 21.5.2022.
//  Copyright © 2022 Lauri-Matti Parppei. All rights reserved.
//

import Foundation

class BeatiOSOutlineView: UITableView, UITableViewDelegate, BeatSceneOutlineView {
	
	@IBOutlet weak var editorDelegate:BeatEditorDelegate!
	var dataProvider:BeatOutlineDataProvider?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		// Register outline view
		self.editorDelegate.register(self)
		
		self.delegate = self
		
		self.backgroundColor = UIColor.black;
		self.backgroundView?.backgroundColor = UIColor.black;
		
		self.dataProvider = BeatOutlineDataProvider(delegate: self.editorDelegate, tableView: self)
		self.dataProvider?.update()
		
		let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeToClose))
		swipe.direction = .left
		self.addGestureRecognizer(swipe)
	}
	
	func reload(with changes: OutlineChanges!) {
		self.reload()
	}
	
	func reloadInBackground() {
		self.reload()
	}
	
	func reload() {
		self.dataProvider?.update()
	}
	
	func visible() -> Bool {
		if self.frame.width > 1 {
			return true
		} else {
			return false
		}
	}
	
	@objc func swipeToClose() {
		self.editorDelegate.toggleSidebar(self)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let i = indexPath.row
		guard let scene = self.editorDelegate.parser.outline[i] as? OutlineScene else { return }
		
		self.editorDelegate.selectedRange = NSMakeRange(NSMaxRange(scene.line.textRange()), 0)
		self.editorDelegate.scroll(to: scene.line)
	}
	
	/// Updates current scene
	var previousLine:Line?
	var selectedItem:OutlineDataItem?
	
	@objc func update() {
		// Do nothing if the line hasn't changed
		if editorDelegate.currentLine() == previousLine { return }
		
		// Spaghetti code follows:
		let snapshot = self.dataProvider!.dataSource.snapshot()

		let oldSelectedItem = selectedItem
		self.selectedItem = nil
		
		for i in 0..<snapshot.numberOfItems {
			// Because items are only created for visible items, we need to scroll to selected item using the snapshot data source
			let item = snapshot.itemIdentifiers(inSection: 0)[i]
			if NSLocationInRange(self.editorDelegate.selectedRange.location, item.range) {
				selectedItem = item
				if (oldSelectedItem != item) {
					scrollToSelectedItem()
				}
			}
			
			// Then update the selected status for each visible item
			if let c = self.cellForRow(at: IndexPath(row: i, section: 0)) {
				let selected = selectedItem == item
				c.setSelected(selected, animated: true)
			}
		}
	}
	
	func scrollToSelectedItem() {
		guard let selectedItem = selectedItem,
			  let dataSource = self.dataProvider?.dataSource,
			  let indexPath = dataSource.indexPath(for: selectedItem) else {
			return
		}

		// Scroll to the selected item's row.
		scrollToRow(at: indexPath, at: .middle, animated: true)
	}
}

class BeatOutlineViewCell:UITableViewCell {
	@IBOutlet var textField:UILabel?
	weak var representedScene:OutlineScene?
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setup()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.backgroundColor = .black
		setup()
	}
	
	func setup() {
		self.backgroundColor = .black

		let selectionView = UIView()
		selectionView.backgroundColor = ThemeManager.shared().outlineHighlight
		self.selectedBackgroundView = selectionView

	}
}
