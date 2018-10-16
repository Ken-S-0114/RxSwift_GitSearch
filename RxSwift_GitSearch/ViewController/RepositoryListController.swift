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
  
  // 観測対象のオブジェクトの一括解放用
  let disposeBag = DisposeBag()
  
  // ViewModelのインスタンス格納用のメンバ変数
  var repositoriesViewModel: RepositoriesViewModel!
  
  // 検索ボックスの値変化を監視対象にする.（テキストが空っぽの場合はデータ取得を行わない）また, 0.5秒のバッファを持たせる
  var rx_searchBarText: Observable<String> {
    return nameSearchBar.rx.text
      .filter { $0 != nil }
      .map { $0! }
      .filter { $0.count > 0 }
      .debounce(0.5, scheduler: MainScheduler.instance)
      .distinctUntilChanged()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupRx()
    setupUI()
  }
  
  // ViewModelを経由してGithubの情報を取得してテーブルビューに検索結果を表示する
  private func setupRx() {
    /**
     * メンバ変数の初期化（検索バーでの入力値の更新をトリガーにしてViewModel側に設置した処理を行う）
     *
     * (フロー1) → 検索バーでの入力値の更新が「データ取得のトリガー」になるので、ViewModel側に定義したfetchRepositories()メソッドが実行される
     * (フロー2) → fetchRepositories()メソッドが実行後は、ViewModel側に定義したメンバ変数rx_repositoriesに値が格納される
     */
    repositoriesViewModel = RepositoriesViewModel(withNameObservable: rx_searchBarText)
    
    
    /**
     * リクエストをして結果が更新されるたびにDriverからはobserverに対して通知が行われ、
     * driveメソッドでバインドしている各UIの更新が働くようにしている。
     *
     * (フロー1) → テーブルビューへの一覧表示
     * (フロー2) → 該当データが0件の場合のポップアップ表示
     */
    // リクエストした結果の更新を元に表示に関する処理を行う（テーブルビューへのデータ一覧の表示処理）
    repositoriesViewModel
      .rx_repositories
      .drive(repositoryListTableView.rx.items) { (tableView, i, repository) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "RepositoryCell", for: IndexPath(row: i, section: 0))
        cell.textLabel?.text = repository.name
        cell.detailTextLabel?.text = repository.html_url
        
        return cell
    }
      .disposed(by: disposeBag)
    
    // リクエストした結果の更新を元に表示に関する処理を行う（取得したデータの件数に応じたエラーハンドリング処理）
    repositoriesViewModel
    .rx_repositories
    .drive(onNext: { repositories in
       // データ取得ができなかった場合にのみ, Alertを表示させる
      if repositories.count == 0 {
        let alert = UIAlertController(title: ":(", message: "No repositories for this user.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // ポップアップを閉じる
        if self.navigationController?.visibleViewController is UIAlertController != true {
          self.present(alert, animated: true, completion: nil)
        }
      }
    })
    .disposed(by: disposeBag)
  }
  
  // 画面に対する初期設定
  private func setupUI() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(tableTapped(_:)))
    repositoryListTableView.addGestureRecognizer(tap)
    
    // キーボードのイベントを監視対象にする
    // Case1. キーボードを開いた場合のイベント
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil)
    
    // Case2. キーボードを閉じた場合のイベント
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil)
  }
  
  // キーボード表示時に発動されるメソッド
  @objc private func keyboardWillShow(_ notification: Notification) {
    // キーボードのサイズを取得する
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
      return
    }
    // 一覧表示用テーブルビューのAutoLayoutの制約を更新して高さをキーボード分だけ縮める
    tableViewBottomConstraint.constant = keyboardFrame.height
    UIView.animate(withDuration: 0.3, animations: {
      self.view.updateConstraints()
    })
  }
  
  // キーボード非表示時に発動されるメソッド
  @objc private func keyboardWillHide(_ notification: Notification) {
    
    // 一覧表示用テーブルビューのAutoLayoutの制約を更新して高さを元に戻す
    tableViewBottomConstraint.constant = 0.0
    UIView.animate(withDuration: 0.3, animations: {
      self.view.updateConstraints()
    })
  }
  
  //メモリ解放時にキーボードのイベント監視対象から除外する
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  // テーブルビューのセルタップ時に発動されるメソッド
  @objc private func tableTapped(_ recognizer: UITapGestureRecognizer) {
    // どのセルがタップされたかを探知する
    let location = recognizer.location(in: repositoryListTableView)
    let path = repositoryListTableView.indexPathForRow(at: location)
    
    // キーボードが表示されているか否かで処理を分ける
    if nameSearchBar.isFirstResponder {
      // キーボードを閉じる
      nameSearchBar.resignFirstResponder()
    } else if let path = path {
      // タップされたセルを中央位置に持ってくる
      repositoryListTableView.selectRow(at: path, animated: true, scrollPosition: .middle)
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
}
