//
//  RepositoryListController.swift
//  RxSwift_GitSearch
//
//  Created by 佐藤賢 on 2018/01/22.
//  Copyright © 2018年 佐藤賢. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAlamofire
import ObjectMapper

final class RepositoryListController: UIViewController {
  
  @IBOutlet weak var nameSearchBar: UISearchBar!
  @IBOutlet weak var repositoryListTableView: UITableView!
  @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
  
  let disposeBag = DisposeBag()
  
  //ViewModelのインスタンス格納用のメンバ変数
  var repositoriesViewModel: RepositoriesViewModel!
  
  //検索ボックスの値変化を監視対象にする（テキストが空っぽの場合はデータ取得を行わない）
  var rx_searchBarText: Observable<String> {
    return nameSearchBar.rx.text
            .filter { $0 != nil }
            .map { $0! }
            .filter { $0.count > 0 }
            .debounce(0.5, scheduler: MainScheduler.instance).distinctUntilChanged()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  //ViewModelを経由してGithubの情報を取得してテーブルビューに検索結果を表示する
  private func setupRx() {

  }
  
  private func setupUI() {
//    let tap = UITapGestureRecognizer
  }
}
