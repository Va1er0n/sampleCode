//
//  KVServerManager.h
//  45-47 DZ
//
//  Created by Admin on 24.07.15.
//  Copyright (c) 2015 Valeriy Krautsou. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KVUser;

@interface KVServerManager : NSObject

@property (strong, nonatomic, readonly) KVUser* currentUser;

+ (KVServerManager*) sharesManager;

// авторизация в вк
- (void) autorizeUser:(void(^)(KVUser* user)) completion;

- (void) getUser:(NSString*) userID
       onSuccess:(void (^)(KVUser* user))success
       onFailure:(void (^)(NSError* error, NSInteger statusCode))failure;

// запрос на получение записей со стены
- (void) getWall:(NSString*) userID
      withOffset:(NSInteger) offset
           count:(NSInteger) count
       onSuccess:(void(^)(NSArray* posts)) success
       onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure;

// запрос на получение комментов для поста
- (void) getCommentOnUserID:(NSString*) userID
                   withPost:(NSString*) postID
                  onSuccess:(void(^)(NSArray* coments)) success
                  onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure;

// запрос на получение списка лайкнувших
- (void) getLikesOnUserID:(NSString*) userID
                 withPost:(NSString*) postID
                onSuccess:(void(^)(NSArray* users)) success
                onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure;

// запрос на проверку лайка
- (void) getLikesWithPost:(NSString*) postID
                onSuccess:(void(^)(void)) success
                onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure;

// пост запрос
- (void) postText:(NSString*) text
           onWall:(NSString*) userID
        onSuccess:(void(^)(id result)) success
        onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure;

// отправка сообщения
- (void) postMessage:(NSString*) text
              onUser:(NSString*) userID
           onSuccess:(void(^)(id result)) success
           onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure;

@end
