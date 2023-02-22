//
//  CreditsSheetView.swift
//  palera1nLoader
//
//  Created by Lakhan Lothiyi on 11/11/2022.
//

import IrregularGradient
import SwiftUI
import SDWebImageSwiftUI

let period: TimeInterval = 3

struct CreditsSheetView: View {
    
    @Binding var isOpen: Bool
    
    var credits: [Person] = [
        Person(name: "Nebula", icon: URL(string: "https://avatars.githubusercontent.com/u/18669106?v=4")!, role: "palera1n Owner", link: URL(string: "https://github.com/itsnebulalol")!),
        Person(name: "Mineek", icon: URL(string: "https://avatars.githubusercontent.com/u/84083936?v=4")!, role: "palera1n Owner", link: URL(string: "https://github.com/mineek")!),
        Person(name: "Ploosh", icon: URL(string: "https://avatars.githubusercontent.com/u/56302322?v=4")!, role: "Universal loader & kernel work", link: URL(string: "https://github.com/guacaplushy")!),
        Person(name: "Nick Chan", icon: URL(string: "https://avatars.githubusercontent.com/u/42699250?v=4")!, role: "C rewrite developer & patch work", link: URL(string: "https://github.com/asdfugil")!),
        Person(name: "Nathan", icon: URL(string: "https://avatars.githubusercontent.com/u/87825638?v=4")!, role: "palera1n Developer", link: URL(string: "https://github.com/verygenericname")!),
        Person(name: "llsc12", icon: URL(string: "https://avatars.githubusercontent.com/u/42747613?v=4")!, role: "palera1n Loader Developer", link: URL(string: "https://github.com/llsc12")!),
        Person(name: "flower", icon: URL(string: "https://avatars.githubusercontent.com/u/97859147?v=4")!, role: "palera1n Icon Designer", link: URL(string: "https://github.com/flowerible")!),
        Person(name: "sourcelocation", icon: URL(string: "https://avatars.githubusercontent.com/u/52459150?v=4")!, role: "Mockup Design and code", link: URL(string: "https://github.com/sourcelocation")!),
        Person(name: "Amy", icon: URL(string: "https://avatars.githubusercontent.com/u/26681721?v=4")!, role: "Pogo Developer", link: URL(string: "https://github.com/elihwyma")!),
        Person(name: "Procursus", icon: URL(string: "https://cdn.discordapp.com/attachments/1017854329887129611/1073349517447008356/PNG_image_3.png")!, role: "Bootstrap", link: URL(string: "https://github.com/ProcursusTeam")!),
        Person(name: "xerub", icon: URL(string: "https://avatars.githubusercontent.com/u/12567734?v=4")!, role: "img4lib & restored_external", link: URL(string: "https://github.com/xerub")!),
        Person(name: "alexia", icon: URL(string: "https://avatars.githubusercontent.com/u/482367?v=4")!, role: "DFU script", link: URL(string: "https://github.com/0xallie")!),
        Person(name: "Cryptic", icon: URL(string: "https://avatars.githubusercontent.com/u/27748705?v=4")!, role: "iBoot64Patcher fork", link: URL(string: "https://github.com/Cryptiiiic")!),
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
            ForEach(credits) { person in
                PersonView(person)
            }
        }
        .navigationTitle("Credits")
    }
    
    @ViewBuilder
    func PersonView(_ person: Person) -> some View {
        Button {
            UIApplication.shared.open(person.link)
        } label: {
            HStack {
                WebImage(url: person.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .frame(height: 80)
                
                VStack(alignment: .leading) {
                    Text(person.name)
                        .font(.title.bold())
                    Text(person.role)
                        .font(.body)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                    .padding()
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Capsule().foregroundColor(.init("CellBackground")).background(.ultraThinMaterial))
            .clipShape(Capsule())
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct Person: Identifiable {
    var id: String { link.absoluteString }
    let name: String
    let icon: URL
    let role: String
    let link: URL
}

struct CreditsSheetView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsSheetView(isOpen: .constant(true))
            .preferredColorScheme(.dark)
    }
}
