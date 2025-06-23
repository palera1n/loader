//
//  TimerManager.swift
//  Loader
//
//  Created by samara on 22.03.2025.
//

import Foundation

class TimerManager {
	private var timer: Timer?
	private var startTime: Date?
	
	func startTimer(timeInterval: TimeInterval, repeats: Bool = true) {
		DispatchQueue.global(qos: .utility).async {
			self.startTime = Date()
			
			self.timer = Timer.scheduledTimer(
				withTimeInterval: timeInterval,
				repeats: repeats,
				block: { _ in }
			)
			
			if let timer = self.timer {
				RunLoop.current.add(timer, forMode: .common)
			}
		}
	}
	
	func invalidateTimerWithReturningSeconds() -> String? {
		guard let timer = timer, startTime != nil else {
			return nil
		}
		
		timer.invalidate()
		self.timer = nil
		
		let elapsed = Date().timeIntervalSince(startTime!)
		startTime = nil
		
		return String(format: "%.1fs", elapsed)
	}
}
