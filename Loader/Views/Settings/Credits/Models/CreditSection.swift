//
//  CreditSection.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import Foundation

// MARK: - Credit Models
struct CreditSection: Decodable {
	let name: String
	let data: [CreditPerson]
}

struct CreditPerson: Decodable {
	let name: String
	let github: String
	let intent: String?
	let desc: String?
}

struct CreditsData: Decodable {
	let sections: [CreditSection]
}
