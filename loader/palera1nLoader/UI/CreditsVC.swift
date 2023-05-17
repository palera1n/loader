//
//  CreditsVC.swift
//  palera1nLoader
//
//  Created by samara on 5/16/23.
//

import UIKit

class CreditsViewController: UIViewController {
    var people: [CreditsPerson] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Credits"
        
        let listView = UITableView(frame: .zero, style: .insetGrouped)
        listView.dataSource = self
        listView.delegate = self
        listView.register(PersonCell.self, forCellReuseIdentifier: "PersonCell")
        view.addSubview(listView)

        people = CreditsData.getCreditsData()
        
        //view
        view.backgroundColor = UIColor.systemGray6
        listView.translatesAutoresizingMaskIntoConstraints = false
        listView.contentInset = UIEdgeInsets(top: -25, left: 0, bottom: 40, right: 0)
        
        NSLayoutConstraint.activate([
            listView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            listView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            listView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            listView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}


extension CreditsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return people.count - 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell", for: indexPath) as! PersonCell
        
        if indexPath.section == 0 {
            let palera1n = people.first!
            cell.configure(with: palera1n)
        } else {
            let person = people[indexPath.row + 1]
            cell.configure(with: person)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let palera1n = people.first!
            let url = palera1n.socialLink
            UIApplication.shared.open(url ?? URL(string: "https://twitter.com/mrbreast")!)
        } else {
            let person = people[indexPath.row + 1]
            let url = person.socialLink
            UIApplication.shared.open(url ?? URL(string: "https://twitter.com/mrbreast")!)
        }
    }
}

class PersonCell: UITableViewCell {
    var personImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 13
        imageView.clipsToBounds = true
        return imageView
    }()
    
    var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    var roleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    func configure(with person: CreditsPerson) {
        nameLabel.text = person.name
        roleLabel.text = person.role
        
        URLSession.shared.dataTask(with: person.pfpURL) { data, _, _ in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.personImageView.image = uiImage
                }
            }
        }
        .resume()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        contentView.addSubview(personImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(roleLabel)
        
        NSLayoutConstraint.activate([
            personImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            personImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            personImageView.widthAnchor.constraint(equalToConstant: 45),
            personImageView.heightAnchor.constraint(equalToConstant: 45),
            
            nameLabel.leadingAnchor.constraint(equalTo: personImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            roleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}

class CreditsData {
    static func getCreditsData() -> [CreditsPerson] {
        let Flower = CreditsPerson(name: "Flower", role: "Loader Development", pfpURL: URL(string: "https://github.com/flowerible.png")!, socialLink: URL(string: "https://github.com/flowerible")!)
        let Staturnz = CreditsPerson(name: "staturnz", role: "Loader Development", pfpURL: URL(string: "https://github.com/staturnzz.png")!, socialLink: URL(string: "https://github.com/staturnzz")!)
        let Nick_Chan = CreditsPerson(name: "Nick Chan", role: "jbinit & palera1n 2.0.0 cli", pfpURL: URL(string: "https://github.com/asdfugil.png")!, socialLink: URL(string: "https://github.com/asdfugil")!)
        let plooshi = CreditsPerson(name: "Tom", role: "KPF & Kernel patches", pfpURL: URL(string: "https://github.com/plooshi.png")!, socialLink: URL(string: "https://github.com/plooshi")!)
        let nebooba = CreditsPerson(name: "Nebula", role: "Introducing a bug", pfpURL: URL(string: "https://github.com/itsnebulalol.png")!, socialLink: URL(string: "https://github.com/itsnebulalol")!)
        let bakera1n = CreditsPerson(name: "dora2ios", role: "jbinit & KPF", pfpURL: URL(string: "https://github.com/kok3shidoll.png")!, socialLink: URL(string: "https://github.com/kok3shidoll")!)
        let palera1n = CreditsPerson(name: "palera1n", role: "We worked hard together to make palera1n possible <3", pfpURL: URL(string: "https://github.com/palera1n.png")!, socialLink: URL(string: "https://palera.in")!)

        return [palera1n, Nick_Chan, plooshi, bakera1n, Flower, Staturnz, nebooba]
    }
}

struct CreditsPerson {
    let name: String
    let role: String
    let pfpURL: URL
    let socialLink: URL?
}
