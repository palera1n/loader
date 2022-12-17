//
//  SettingsSheetView.swift
//  palera1nLoader
//
//  Created by Lakhan Lothiyi on 26/11/2022.
//

import Foundation
import SwiftUI
import IrregularGradient

struct SettingsSheetView: View {
    @Binding var isOpen: Bool
    @EnvironmentObject var console: Console
    
    var tools: [Tool] = [
        Tool(name: "UICache", desc: "Refresh icon cache of jailbreak apps", action: ToolAction.uicache),
        Tool(name: "Remount r/w", desc: "Remounts the rootfs and preboot as read/write", action: ToolAction.mntrw),
        Tool(name: "Launch Daemons", desc: "Start daemons using launchctl", action: ToolAction.daemons),
        Tool(name: "Respring", desc: "Restart SpringBoard", action: ToolAction.respring),
        Tool(name: "Activate Tweaks", desc: "Runs substitute-launcher to activate tweaks", action: ToolAction.tweaks),
        Tool(name: "Do All", desc: "Do all of the above", action: ToolAction.all),
    ]
    
    var packagemanagers: [PackageManager] = [
        PackageManager(name: "Sileo", desc: "Modern package manager (recommended)", action: PackageManagers.sileo),
        PackageManager(name: "Zebra", desc: "Cydia-ish look and feal with modern features", action: PackageManagers.zebra),
        PackageManager(name: "Cydia", desc: "Old and nostalgic package manager (not recommended, partially broken)", action: PackageManagers.cydia),
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .irregularGradient(colors: palera1nColorGradients, backgroundColor: palera1nColorGradients[1], animate: true, speed: 0.5)
                    .blur(radius: 100)
                
                main
            }
        }
    }
    
    @ViewBuilder
    var main: some View {
        ScrollView {
            ForEach(tools) { tool in
                ToolsView(tool)
            }

            Text("Package Managers")
                .fontWeight(.bold)
                .font(.title)
                .padding()

            ForEach(packagemanagers) { pm in
                PMView(pm)
            }
        }
        .navigationTitle("Tools")
    }

    @ViewBuilder
    func ToolsView(_ tool: Tool) -> some View {
        Button {
            self.isOpen.toggle()

            switch tool.action {
                case .uicache:
                    spawn(command: "/usr/bin/uicache", args: ["-a"], root: true)
                    console.log("[*] Ran uicache")
                case .mntrw:
                    spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
                    spawn(command: "/sbin/mount", args: ["-uw", "/" ], root: true)
                    console.log("[*] Remounted the rootfs and preboot as read/write")
                case .daemons:
                    spawn(command: "/bin/launchctl", args: ["bootstrap", "system", "/Library/LaunchDaemons"], root: true)
                    console.log("[*] Launched daemons")
                case .respring:
                    spawn(command: "/usr/bin/sbreload", args: [], root: true)
                    console.log("[*] Resprung the device... but you probably won't see this :)")
                case .tweaks:
                    spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)
                    console.log("[*] Started Substitute, respring to enable tweaks")
                case .all:
                    spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
                    spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
                    console.log("[*] Remounted the rootfs and preboot as read/write")

                    spawn(command: "/usr/bin/uicache", args: ["-a"], root: true)
                    console.log("[*] Ran uicache")

                    spawn(command: "/bin/launchctl", args: ["bootstrap", "system", "/Library/LaunchDaemons"], root: true)
                    console.log("[*] Launched daemons")

                    spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)
                    console.log("[*] Started Substitute, respring to enable tweaks")

                    spawn(command: "/usr/bin/sbreload", args: [], root: true)
                    console.log("[*] Resprung the device... but you probably won't see this :)")
            }
        } label: {
            HStack {
                Image(systemName: "wrench")
                
                VStack(alignment: .leading) {
                    Text(tool.name)
                        .font(.title2.bold())
                    Text(tool.desc)
                        .font(.caption)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Capsule().foregroundColor(.init("CellBackground")).background(.ultraThinMaterial))
            .clipShape(Capsule())
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func PMView(_ pm: PackageManager) -> some View {
        Button {
            self.isOpen.toggle()

            switch pm.action {
                case .sileo:
                    console.log("[*] Installing Sileo")

                    guard let deb = Bundle.main.path(forResource: "sileo", ofType: "deb") else {
                        let msg = "Could not find Sileo"
                        console.error("[-] \(msg)")
                        print("[palera1n] \(msg)")
                        return
                    }

                    let ret = spawn(command: "/usr/bin/dpkg", args: ["-i", deb], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Failed to install Sileo. Status: \(ret)")
                            return
                        }

                        console.log("[*] Installed Sileo")
                    }
                case .zebra:
                    console.log("[*] Installing Zebra")

                    guard let deb = Bundle.main.path(forResource: "zebra", ofType: "deb") else {
                        let msg = "Could not find Zebra"
                        console.error("[-] \(msg)")
                        print("[palera1n] \(msg)")
                        return
                    }

                    let ret = spawn(command: "/usr/bin/dpkg", args: ["-i", deb], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Failed to install Zebra. Status: \(ret)")
                            return
                        }

                        console.log("[*] Installed Zebra")
                    }
                case .cydia:
                    console.log("[*] Installing Cydia dependencies")

                    guard let deb = Bundle.main.path(forResource: "cydia", ofType: "deb") else {
                        let msg = "Could not find Cydia"
                        console.error("[-] \(msg)")
                        print("[palera1n] \(msg)")
                        return
                    }

                    let ret = spawn(command: "/usr/bin/apt-get", args: ["install", "bzip2", "xz-utils", "zstd", "-y", "--allow-unauthenticated"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Failed to install Cydia. Status: \(ret)")
                            return
                        }

                        console.log("[*] Installing Cydia")
                        let ret = spawn(command: "/usr/bin/dpkg", args: ["-i", deb], root: true)
                        DispatchQueue.main.async {
                            if ret != 0 {
                                console.error("[-] Failed to install Cydia. Status: \(ret)")
                                return
                            }

                            console.log("[*] Installed Cydia")
                        }
                    }
            }
        } label: {
            HStack {
                Image(systemName: "wrench")
                
                VStack(alignment: .leading) {
                    Text(pm.name)
                        .font(.title2.bold())
                    Text(pm.desc)
                        .font(.caption)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Capsule().foregroundColor(.init("CellBackground")).background(.ultraThinMaterial))
            .clipShape(Capsule())
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// tools
public enum ToolAction {
    case uicache
    case mntrw
    case daemons
    case respring
    case tweaks
    case all
}

struct Tool: Identifiable {
    var id: String { name }
    let name: String
    let desc: String
    let action: ToolAction
}

// package managers
public enum PackageManagers {
    case sileo
    case zebra
    case cydia
}

struct PackageManager: Identifiable {
    var id: String { name }
    let name: String
    let desc: String
    let action: PackageManagers
}

struct SettingsSheetView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheetView(isOpen: .constant(true))
            .preferredColorScheme(.dark)
    }
}
