//
//  RepositoriesViewModel.swift
//  RxSwift_GitSearch
//
//  Created by 佐藤賢 on 2018/01/22.
//  Copyright © 2018年 佐藤賢. All rights reserved.
//

import RxSwift
import RxCocoa
import ObjectMapper
import RxAlamofire


struct RepositoriesViewModel {

  lazy var rx_repositories: Driver<[Repository]> = self.fetchRepositories()
  
  // 監視対象のメンバ変数
  fileprivate var repositoryName: Observable<String>
  
  // 監視対象の変数初期化処理(イニシャライザ)
  init(withNameObservable nameObservable: Observable<String>) {
    self.repositoryName = nameObservable

  }
  
  // GithubAPIへアクセスしデータを取得して, ViewController側のUI処理とバインドするためにDriverに変換をする処理
  fileprivate func fetchRepositories() -> Driver<[Repository]> {

    // Observableな変数に対して、「.subscribeOn」→「.observeOn」→「.observeOn」...という形で数珠つなぎで処理を実行
    return repositoryName
      
      // 処理Phase1: 見た目に関する処理
      .subscribeOn(MainScheduler.instance)
      .do(onNext: { response in
        //ネットワークインジケータを表示状態にする
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
      })
      
      // 処理Phase2: 下記のAPI(GithubAPI)のエンドポイントへRxAlamofire経由でのアクセスをする
      .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
      .flatMapLatest { text in
        // APIからデータを取得する
        return RxAlamofire
          .requestJSON(.get, "https://api.github.com/users/\(text)/repos")
          .debug()
          .catchError { error in
            //エラー発生時の処理(この場合は値を持たせずにここで処理を止めてしまう)
            return Observable.never()
        }
      }
      
      // 処理Phase3: ModelクラスとObjectMapperで定義した形のデータを作成する
      .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
      .map { (response, json) -> [Repository] in
        // APIからレスポンスが取得できた場合には, Modelクラスに定義した形のデータを返却する
        if let repos = Mapper<Repository>().mapArray(JSONObject: json) {
          return repos
        } else {
          return []
        }
      }
      
      // 処理Phase4: データが受け取れた際の見た目に関する処理とDriver変換
      .observeOn(MainScheduler.instance)
      .do(onNext: { response in
        //ネットワークインジケータを非表示状態にする
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
      })
      
      //Driverに変換する
      .asDriver(onErrorJustReturn: [])
  }
  
}
