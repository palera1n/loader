// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "NimbleKit",
	platforms: [
		.iOS(.v14),
		.tvOS(.v14)
	],
	products: [
		.library(name: "NimbleAnimations", targets: ["NimbleAnimations"]),
		.library(name: "NimbleExtensions", targets: ["NimbleExtensions"]),
		.library(name: "NimbleJSON", targets: ["NimbleJSON"]),
		.library(name: "NimbleViewControllers", targets: ["NimbleViewControllers"]),
	],
	targets: [
		.target(name: "NimbleAnimations",
			dependencies: ["NimbleExtensions"]
		),
		.target(name: "NimbleViewControllers",
			dependencies: ["NimbleExtensions"]
		),
		.target(name: "NimbleExtensions",
			dependencies: []
		),
		.target(name: "NimbleJSON",
			dependencies: []
		)
	]
)
