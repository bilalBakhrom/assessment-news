//
//  HomeViewController.swift
//  NBK-Test-News
//
//  Created by Bilal Bakhrom on 19/10/2022.
//

import UIKit
import SwiftUI
import NewsNetwork

public class HomeViewController: UIViewController {
    public var viewModel: HomeViewModel!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(NewsCell.self)
            tableView.showsVerticalScrollIndicator = false
            tableView.dataSource = self
            tableView.delegate = self
            tableView.backgroundColor = .clear
            tableView.separatorStyle = .none
        }
    }

    @IBOutlet weak var loader: UIActivityIndicatorView!
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        set(viewModel: HomeViewModel())
    }
    
    public func set(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        bind()
        viewModel.fetch()
    }
    
    public func setupNavigationBar() {
        setNavTitle("News")
        
        // Add Filter Button
        let image = UIImage(systemName: "line.3.horizontal.decrease.circle")
        let filterButton = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(handleFilterButtonClick))
        navigationItem.rightBarButtonItem = filterButton
    }
    
    private func bind() {
        viewModel.addArticlesObserver { [weak self] _, meta in
            guard let self else { return }
            
            let rows = (meta.start...meta.end).map { IndexPath(row: $0, section: 0) }
            self.tableView.insertRows(at: rows, with: .bottom)
        }
        
        viewModel.addErrorObserver { [weak self] error in
            guard let self else { return }
            
            self.showError(error)
        }
        
        viewModel.addLoaderObserver { [weak self] isLoading in
            guard let self else { return }
            isLoading ? self.loader.startAnimating() : self.loader.stopAnimating()
        }
    }
    
    private func showError(_ error: NError) {
        print("ERROR")
    }
    
    // MARK: - Actions
    @objc private func handleFilterButtonClick() {
        let filterVM = FilterViewModel(
            country: self.viewModel.listManager.country,
            category: self.viewModel.listManager.category)
        
        filterVM.addObserver { [weak self] country, category in
            self?.viewModel.listManager.country = country
            self?.viewModel.listManager.category = category
            self?.viewModel.reset()
            self?.tableView.reloadData()
            self?.viewModel.fetch()
        }
        
        let view = FilterView(viewModel: filterVM)
        let hostingController = UIHostingController(rootView: view)
        present(hostingController, animated: true)
    }
}

extension HomeViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.articles.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(NewsCell.self, for: indexPath)
        cell.configure(with: viewModel.articles[indexPath.row])
        
        if indexPath.row == viewModel.articles.count - 1 {
            viewModel.fetch()
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.width * 0.65
    }
}

extension HomeViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = viewModel.articles[indexPath.row]
        let detailsView = DetailsView(viewModel: DetailsViewModel(article: article))
        let hostingController = UIHostingController(rootView: detailsView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
}
