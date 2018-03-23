//
//  Repository.swift
//  RxSwift_GitSearch
//
//  Created by 佐藤賢 on 2018/01/22.
//  Copyright © 2018年 佐藤賢. All rights reserved.
//

import ObjectMapper

class Repository: Mappable {
  
  var identifier: Int!
  var html_url: String!
  var name: String!
  
  required init?(map: Map) {}
  
  //ObjectMapperを利用したデータのマッピング
  func mapping(map: Map) {
    identifier <- map["id"]
    html_url <- map["html_url"]
    name <- map["name"]
  }
}
