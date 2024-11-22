import UIKit
import CoreLocation

final class MainTableViewCell: UITableViewCell {
    static let identifier = "CustomTableViewCell"
    
    private lazy var imageAvatar: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var destinationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageAvatar.layer.cornerRadius = imageAvatar.bounds.height / 2
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureText(_ labelText: String, _ destination: String, _ image: String) {
        nameLabel.text = labelText
        destinationLabel.text = destination
        imageAvatar.image = UIImage(named: image)
    }
    
    private func setUpSubviews() {
        contentView.addSubview(imageAvatar)
        contentView.addSubview(nameLabel)
        contentView.addSubview(destinationLabel)
        
        NSLayoutConstraint.activate([
            imageAvatar.widthAnchor.constraint(equalTo: imageAvatar.heightAnchor),
            imageAvatar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            imageAvatar.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            imageAvatar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            nameLabel.leadingAnchor.constraint(equalTo: imageAvatar.trailingAnchor, constant: 5),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            
            destinationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            destinationLabel.leadingAnchor.constraint(equalTo: imageAvatar.trailingAnchor, constant: 5),
            destinationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}
