//
//  HomeViewController.swift
//  ToDoList
//
//  Created by Radu Ursache on 20/02/2019.
//  Copyright © 2019 Radu Ursache. All rights reserved.
//

import UIKit
import IceCream

class HomeViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addTaskButton: UIButton!
    
    var homeDataSource = [HomeItemModel]()
    var selectedItem = HomeItemModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !Utils().userIsLoggedIniCloud() {
            Utils().showErrorToast(message: "You are not logged in iCloud. Your tasks won't be synced!".localized())
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadData()
    }

    override func setupUI() {
        super.setupUI()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "ToDoList", style: .done, target: self, action: #selector(self.titleButtonAction))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.itemWith(colorfulImage: UIImage(named: "settingsIcon")!, target: self, action: #selector(self.settingsButtonAction))
        
        self.addTaskButton.addTarget(self, action: #selector(self.addTaskButtonAction), for: .touchUpInside)
        
        Utils().themeView(view: self.addTaskButton)
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
    }
    
    override func setupBindings() {
        super.setupBindings()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.newCloudDataReceived), name: Notifications.cloudKitNewData.name, object: nil)
    }
    
    @objc func titleButtonAction() {
        self.showOK(title: "ToDoList", message: "A simple ToDoList written in Swift 4.2\n\nRanduSoft 2019")
    }
    
    @objc func settingsButtonAction() {
        self.loadData()
    }
    
    func loadData() {
        let allCount = RealmManager.sharedInstance.getTasks().count
        let todayCount = RealmManager.sharedInstance.getTodayTasks().count
        let tomorrowCount = RealmManager.sharedInstance.getTomorrowTasks().count
        let weekCount = RealmManager.sharedInstance.getWeekTasks().count
        
        self.homeDataSource = [
            HomeItemModel(title: "All Tasks", icon: "menu_all", listType: .All, count: allCount),
            HomeItemModel(title: "Today", icon: "menu_today", listType: .Today, count: todayCount),
            HomeItemModel(title: "Tomorrow", icon: "menu_tomorrow", listType: .Tomorrow, count: tomorrowCount),
            HomeItemModel(title: "Next 7 Days", icon: "menu_week", listType: .Week, count: weekCount)
                                ]
        
        self.tableView.reloadData()
    }
    
    @objc func newCloudDataReceived() {
        print("New iCloud data received")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if !UserDefaults.standard.bool(forKey: Config.UserDefaults.neverSyncedBefore) {
                UserDefaults.standard.set(true, forKey: Config.UserDefaults.neverSyncedBefore)
                Utils().showSuccessToast(message: "iCloud data synced succesfully!".localized())
            }
            
            self.loadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTasksVC" {
            guard let tasksVC = segue.destination as? TasksViewController else { return }

            tasksVC.title = self.selectedItem.title
            tasksVC.selectedType = self.selectedItem.listType
        }
    }
    
    @objc func addTaskButtonAction() {
        let addTaskVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addTaskVC") as! AddTaskViewController
        addTaskVC.onCompletion = {
            self.loadData()
        }
        
        let navigationController = UINavigationController(rootViewController: addTaskVC)
        navigationController.modalPresentationStyle = .custom
        
        self.present(navigationController, animated: true, completion: nil)
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.homeDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableViewCell.getIdentifier(), for: indexPath) as! HomeTableViewCell
        
        let currentItem = self.homeDataSource[indexPath.row]
        
        cell.itemImageView.image = UIImage(named: currentItem.icon)
        cell.itemTitle.text = currentItem.title
        cell.itemCountLabel.text = String(currentItem.count)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.selectedItem = self.homeDataSource[indexPath.row]
        
        self.performSegue(withIdentifier: "goToTasksVC", sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
