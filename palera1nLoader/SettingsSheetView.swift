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
    
    var serverURL = "https://static.palera.in"
    
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
        PackageManager(name: "Zebra", desc: "Cydia-ish look and feel with modern features", action: PackageManagers.zebra),
    ]
    
    var openers: [Opener] = [
        Opener(name: "Sileo", desc: "Open the Sileo app", action: Openers.sileo),
        Opener(name: "TrollHelper", desc: "Open the TrollHelper app, clicking install will resolve iPad uicache issues", action: Openers.trollhelper),
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

            Text("Openers")
                .fontWeight(.bold)
                .font(.title)

            Text("Mainly for iPads (and their uicache issues), specified app must be installed.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            ForEach(openers) { opener in
                OpenersView(opener)
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
    
    func deleteFile(file: String) -> Void {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func downloadFile(file: String) -> Void {
        console.log("[*] Downloading \(file)")
        deleteFile(file: file)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        let url = URL(string: "\(serverURL)/\(file)")!
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.downloadTask(with: url) { tempLocalUrl, response, error in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: fileURL)
                    self.console.log("[*] Downloaded \(file)")
                    semaphore.signal()
                } catch (let writeError) {
                    self.console.error("[-] Could not copy file to disk: \(writeError)")
                    print("[palera1n] Could not copy file to disk: \(writeError)")
                }
            } else {
                self.console.error("[-] Could not download file: \(error?.localizedDescription ?? "Unknown error")")
                print("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        task.resume()
        semaphore.wait()
    }

    @ViewBuilder
    func PMView(_ pm: PackageManager) -> some View {
        Button {
            self.isOpen.toggle()

            switch pm.action {
                case .sileo:
                    console.log("[*] Installing Sileo")
                    DispatchQueue.global(qos: .utility).async { [self] in
                        downloadFile(file: "sileo.deb")
                                                               
                        DispatchQueue.global(qos: .utility).async { [self] in
                            guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sileo.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                                let msg = "Failed to find Sileo"
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
                        }
                    }
                case .zebra:
                    console.log("[*] Installing Zebra")
                    DispatchQueue.global(qos: .utility).async { [self] in
                        downloadFile(file: "zebra.deb")
                                                               
                        DispatchQueue.global(qos: .utility).async { [self] in
                            guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("zebra.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                                let msg = "Failed to find Sileo"
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

    @ViewBuilder
    func OpenersView(_ opener: Opener) -> some View {
        Button {
            self.isOpen.toggle()

            switch opener.action {
                case .sileo:
                    let ret = spawn(command: "/usr/bin/uiopen", args: ["--path", "/Applications/Sileo.app"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Failed to open Sileo. Status: \(ret)")
                            return
                        }

                        console.log("[*] Opened Sileo")
                    }
                case .trollhelper:
                    let ret = spawn(command: "/usr/bin/uiopen", args: ["--path", "/Applications/TrollStorePersistenceHelper.app"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Failed to open TrollHelper. Status: \(ret)")
                            return
                        }

                        console.log("[*] Opened TrollHelper")
                    }
            }
        } label: {
            HStack {
                Image(systemName: "wrench")
                
                VStack(alignment: .leading) {
                    Text("Open \(opener.name)")
                        .font(.title2.bold())
                    Text(opener.desc)
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
}

struct PackageManager: Identifiable {
    var id: String { name }
    let name: String
    let desc: String
    let action: PackageManagers
}

// openers
public enum Openers {
    case sileo
    case trollhelper
}

struct Opener: Identifiable {
    var id: String { name }
    let name: String
    let desc: String
    let action: Openers
}

struct SettingsSheetView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheetView(isOpen: .constant(true))
            .preferredColorScheme(.dark)
    }
}
