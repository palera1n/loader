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
    
    @State var rootful : Bool = false
    @State var inst_prefix: String = "unset"
    
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
    
    var openers: [Opener] = {
        if (FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")) {
            return [
                Opener(name: "Sileo", desc: "Open the Sileo app", action: Openers.sileo),
                Opener(name: "TrollHelper", desc: "Open the TrollHelper app, clicking install will resolve iPad uicache issues", action: Openers.trollhelper)
            ]
        } else {
            return [
                Opener(name: "TrollHelper", desc: "Open the TrollHelper app, clicking install will resolve iPad uicache issues", action: Openers.trollhelper)
            ]
        }
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .irregularGradient(colors: palera1nColorGradients, backgroundColor: palera1nColorGradients[1], animate: true, speed: 0.5)
                    .blur(radius: 100)
                
                main
            }
        }
        .alert("Warning", isPresented: $showAlert) {
            Button("Re-bootstrap anyway") {
                console.log("[*] Starting re-bootstrap process")
                strap()
            }
            Button("Cancel (Recommended)") {
            }
        } message: {
            Text("Your device already has the bootstrap installed. Re-bootstrapping most times is not needed, and may cause problems.")
        }
    }
    
    @ViewBuilder
    var main: some View {
        ScrollView {
        
            if (FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")) {
                        ForEach(tools) { tool in
                            ToolsView(tool)
                        }
                    }
            
            if (FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")) {
                ToolsView(Tool(name: "Remove", desc: "Remove jailbreak", action: ToolAction.nuke))
                }
            
            if ( FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")) {                ToolsView(Tool(name: "Re-Install", desc: "Re-Install the bootstrap", action: ToolAction.rebootstrap))
            } else {
                ToolsView(Tool(name: "Install", desc: "Install the bootstrap", action: ToolAction.bootstrap))
            }
            
            if ( FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")) {
                    
                    Text("Package Managers")
                        .fontWeight(.bold)
                        .font(.title)
                
                    Text("These options will (re)install your desired package manager.")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                
                    ForEach(packagemanagers) { pm in
                        PMView(pm)

                    }
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

    @State private var showAlert: Bool = false
    @ViewBuilder
    func ToolsView(_ tool: Tool) -> some View {
        Button {
            if (inst_prefix == "unset") {
                guard let helper = Bundle.main.path(forAuxiliaryExecutable: "palera1nHelper") else {
                    let msg = "Could not find helper?"
                    console.error("[-] \(msg)")
                    print("[palera1n] \(msg)")
                    return
                }

                let ret = spawn(command: helper, args: ["-f"], root: true)

                rootful = ret == 0 ? false : true

                inst_prefix = rootful ? "" : "/var/jb"
            }
                
            switch tool.action {
                case .uicache:
                    self.isOpen.toggle()
                    spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
                    console.log("[*] Ran uicache")
                case .mntrw:
                    self.isOpen.toggle()
                    spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
                    spawn(command: "/sbin/mount", args: ["-uw", "/" ], root: true)
                    console.log("[*] Remounted the rootfs and preboot as read/write")
                case .daemons:
                    self.isOpen.toggle()
                    spawn(command: "\(inst_prefix)/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
                    console.log("[*] Launched daemons")
                case .respring:
                    self.isOpen.toggle()
                    spawn(command: "\(inst_prefix)/usr/bin/sbreload", args: [], root: true)
                    console.log("[*] Resprung the device... but you probably won't see this :)")
                case .tweaks:
                    self.isOpen.toggle()
                    if rootful {
                        spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)
                    } else {
                        spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)
                    }
                    console.log("[*] Started Substitute, respring to enable tweaks")
                case .all:
                    self.isOpen.toggle()
                    spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
                    spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
                    console.log("[*] Remounted the rootfs and preboot as read/write")

                    spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
                    console.log("[*] Ran uicache")

                    spawn(command: "\(inst_prefix)/bin/launchctl", args: ["bootstrap", "system", "\(inst_prefix)/Library/LaunchDaemons"], root: true)
                    console.log("[*] Launched daemons")

                    if rootful {
                        spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)
                    } else {
                        spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)
                    }
                    console.log("[*] Started tweaks, respring to enable tweaks")

                    spawn(command: "\(inst_prefix)/usr/bin/sbreload", args: [], root: true)
                    console.log("[*] Resprung the device... but you probably won't see this :)")
                case .bootstrap:
                    console.log("[*] Starting bootstrap process")
                    strap()
                case .rebootstrap:
                    showAlert = true
                case .nuke:
                    nuke()
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
    
    var serverURL = "https://static.palera.in/rootless/"
    private func deleteFile(file: String) -> Void {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func downloadFile(file: String, tb: ToolbarStateMoment, server: String = "https://static.palera.in/rootless/") -> Void {
        console.log("[*] Downloading \(file)")
        deleteFile(file: file)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        let url = URL(string: "\(server)/\(file)")!
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
                    tb.toolbarState = .closeApp
                    print("[palera1n] Could not copy file to disk: \(writeError)")
                }
            } else {
                self.console.error("[-] Could not download file: \(error?.localizedDescription ?? "Unknown error")")
                tb.toolbarState = .closeApp
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
            let tb = ToolbarStateMoment.s
            
            if (inst_prefix == "unset") {
                guard let helper = Bundle.main.path(forAuxiliaryExecutable: "palera1nHelper") else {
                    let msg = "Could not find helper?"
                    console.error("[-] \(msg)")
                    print("[palera1n] \(msg)")
                    return
                }

                let ret = spawn(command: helper, args: ["-f"], root: true)

                rootful = ret == 0 ? false : true

                inst_prefix = rootful ? "" : "/var/jb"
            }
            switch pm.action {
                case .sileo:
                    if (rootful) {
                        console.log("[*] Installing Sileo")
                        DispatchQueue.global(qos: .utility).async { [self] in
                            downloadFile(file: "sileo.deb", tb: tb, server: "https://static.palera.in/")

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
                    }
                case .zebra:
                    if (rootful) {
                        console.log("[*] Installing Zebra")
                        DispatchQueue.global(qos: .utility).async { [self] in
                            downloadFile(file: "zebra.deb", tb: tb, server: "https://static.palera.in/")

                            DispatchQueue.global(qos: .utility).async { [self] in
                                guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("zebra.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                                    let msg = "Failed to find Zebra"
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
            
            if (inst_prefix == "unset") {
                guard let helper = Bundle.main.path(forAuxiliaryExecutable: "palera1nHelper") else {
                    let msg = "Could not find helper?"
                    console.error("[-] \(msg)")
                    print("[palera1n] \(msg)")
                    return
                }

                let ret = spawn(command: helper, args: ["-f"], root: true)

                rootful = ret == 0 ? false : true

                inst_prefix = rootful ? "" : "/var/jb"
            }

            switch opener.action {
                case .sileo:
                    var ret: Int = 0
                    if rootful {
                        ret = spawn(command: "\(inst_prefix)/usr/bin/uiopen", args: ["--path", "\(inst_prefix)/Applications/Sileo.app"], root: true)
                        if ret != 0 {
                            ret = spawn(command: "\(inst_prefix)/usr/bin/uiopen", args: ["--path", "\(inst_prefix)/Applications/Sileo-Nightly.app"], root: true)
                            console.warn("[!] Sileo.app not found, opening Sileo-Nightly.app instead")
                        }
                    } else {
                        ret = spawn(command: "\(inst_prefix)/usr/bin/uiopen", args: ["--path", "\(inst_prefix)/Applications/Sileo.app"], root: true)
                        if ret != 0 {
                            ret = spawn(command: "\(inst_prefix)/usr/bin/uiopen", args: ["--path", "\(inst_prefix)/Applications/Sileo-Nightly.app"], root: true)
                            console.warn("[!] Sileo.app not found, opening Sileo-Nightly.app instead")
                        }
                    }
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Failed to open Sileo. Status: \(ret)")
                            console.warn("[!] Do you have it installed?")
                            return
                        }

                        console.log("[*] Opened Sileo")
                    }
                case .trollhelper:
                    let ret = spawn(command: "\(inst_prefix)/usr/bin/uiopen", args: ["--path", "\(inst_prefix)/Applications/TrollStorePersistenceHelper.app"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Failed to open TrollHelper. Status: \(ret)")
                            console.warn("[!] Do you have it installed?")
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
    
    private func nuke() {
        let tb = ToolbarStateMoment.s
        tb.toolbarState = .disabled
        
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "palera1nHelper") else {
            let msg = "Could not find helper?"
            console.error("[-] \(msg)")
            tb.toolbarState = .closeApp
            print("[palera1n] \(msg)")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        
        let rootful = ret == 0 ? false : true
                    
        let inst_prefix = rootful ? "/" : "/var/jb"
        
        if !rootful {
            console.log("[*] Unregistering apps")
            DispatchQueue.global(qos: .utility).async {
                // remove all jb apps from uicache
                let fm = FileManager.default
                let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
                for app in apps ?? [] {
                    if app.hasSuffix(".app") {
                        let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                        DispatchQueue.main.async {
                            if ret != 0 {
                                console.error("[-] Failed to unregister \(app): \(ret)")
                                tb.toolbarState = .closeApp
                                return
                            }
                        }                
                    }
                }
                
                console.log("[*] Removing jailbreak!")
                let ret = spawn(command: helper, args: ["-r"], root: true)
                DispatchQueue.main.async {
                    if ret != 0 {
                        console.error("[-] Failed to remove jailbreak: \(ret)")
                        tb.toolbarState = .closeApp
                        return
                    }
                    console.log("[*] Jailbreak removed!")
                    tb.toolbarState = .closeApp
                }
            }
        }
    }
    
    private func strap() -> Void {
        let tb = ToolbarStateMoment.s
        tb.toolbarState = .disabled
         
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "palera1nHelper") else {
            let msg = "Could not find helper?"
            console.error("[-] \(msg)")
            tb.toolbarState = .closeApp
            print("[palera1n] \(msg)")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
                    
        let rootful = ret == 0 ? false : true
                    
        let inst_prefix = rootful ? "/" : "/var/jb"
        
        DispatchQueue.global(qos: .utility).async { [self] in
            if rootful {
                downloadFile(file: "bootstrap.tar", tb: tb, server: "https://static.palera.in")
                downloadFile(file: "sileo.deb", tb: tb, server: "https://static.palera.in")
                downloadFile(file: "straprepo.deb", tb: tb, server: "https://static.palera.in")
            } else {
                downloadFile(file: "bootstrap.tar", tb: tb)
                downloadFile(file: "sileo.deb", tb: tb)
                downloadFile(file: "palera1nrepo.deb", tb: tb)
            }

            DispatchQueue.main.async {
                guard let tar = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("bootstrap.tar").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let msg = "Failed to find bootstrap"
                    console.error("[-] \(msg)")
                    tb.toolbarState = .closeApp
                    print("[palera1n] \(msg)")
                    return
                }

                guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sileo.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let msg = "Could not find Sileo"
                    console.error("[-] \(msg)")
                    tb.toolbarState = .closeApp
                    print("[palera1n] \(msg)")
                    return
                }
                
                var strapRepo : String?
                
                if rootful {
                    strapRepo = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("straprepo.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
                    guard strapRepo != nil else {
                        let msg = "Could not find strap repo deb"
                        console.error("[-] \(msg)")
                        tb.toolbarState = .closeApp
                        print("[palera1n] \(msg)")
                        return
                    }
                } else {
                    strapRepo = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("palera1nrepo.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
                    guard strapRepo != nil else {
                        let msg = "Could not find palera1n repo deb"
                        console.error("[-] \(msg)")
                        tb.toolbarState = .closeApp
                        print("[palera1n] \(msg)")
                        return
                    }
                }

                DispatchQueue.global(qos: .utility).async {
                    spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
                    
                    if rootful {
                        spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
                    }
                    
                    let ret = spawn(command: helper, args: ["-i", tar], root: true)
                    
                    spawn(command: "\(inst_prefix)/usr/bin/chmod", args: ["4755", "\(inst_prefix)/usr/bin/sudo"], root: true)
                    spawn(command: "\(inst_prefix)/usr/bin/chown", args: ["root:wheel", "\(inst_prefix)/usr/bin/sudo"], root: true)
                    
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Error installing bootstrap. Status: \(ret)")
                            tb.toolbarState = .closeApp
                            return
                        }
                        
                        console.log("[*] Preparing Bootstrap")
                        DispatchQueue.global(qos: .utility).async {
                            let ret = spawn(command: "\(inst_prefix)/usr/bin/sh", args: ["\(inst_prefix)/prep_bootstrap.sh"], root: true)
                            DispatchQueue.main.async {
                                if ret != 0 {
                                    console.error("[-] Failed to prepare bootstrap. Status: \(ret)")
                                    tb.toolbarState = .closeApp
                                    return
                                }
                                
                                console.log("[*] Installing packages")
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb, strapRepo!], root: true)
                                    DispatchQueue.main.async {
                                        if ret != 0 {
                                            console.error("[-] Failed to install packages. Status: \(ret)")
                                            tb.toolbarState = .closeApp
                                            return
                                        }

                                        console.log("[*] Running uicache")
                                        DispatchQueue.global(qos: .utility).async {
                                            let ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
                                            DispatchQueue.main.async {
                                                if ret != 0 {
                                                    console.error("[-] Failed to uicache. Status: \(ret)")
                                                    tb.toolbarState = .closeApp
                                                    return
                                                }

                                                console.log("[*] Finished installing! Enjoy!")
                                                tb.toolbarState = .respring
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
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
    case bootstrap
    case rebootstrap
    case nuke
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
