//
//  KVServerManager.m
//  45-47 DZ
//
//  Created by Admin on 24.07.15.
//  Copyright (c) 2015 Valeriy Krautsou. All rights reserved.
//

#import "KVServerManager.h"
#import "AFNetworking.h"
#import "KVAccessToken.h"
#import "KVLoginViewController.h"

#import "KVComment.h"
#import "KVUser.h"
#import "KVPost.h"

@interface KVServerManager ()
@property (strong, nonatomic) AFHTTPRequestOperationManager* requestOperationManager;
@property (strong, nonatomic) KVAccessToken* accessToken;
@end

@implementation KVServerManager

+ (KVServerManager*) sharesManager {
    
    static KVServerManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[KVServerManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        NSURL* url = [NSURL URLWithString:@"https://api.vk.com/method/"];
        
        self.requestOperationManager =
        [[AFHTTPRequestOperationManager alloc] initWithBaseURL:url];
    }
    return self;
}

// авторизация в вк
- (void) autorizeUser:(void(^)(KVUser* user)) completion {
    
    KVLoginViewController* vc = [[KVLoginViewController alloc]
                                 initWithCompletionBlock:^(KVAccessToken *token) {
                                     
                                     self.accessToken = token;
                                     
                                     if (token) {
                                         [self getUser:self.accessToken.userID
                                             onSuccess:^(KVUser *user) {
                                                 
                                                 if (completion) {
                                                     completion(user);
                                                 }
                                                 
                                             }
                                             onFailure:^(NSError *error, NSInteger statusCode) {
                                                 
                                                 if (completion) {
                                                     completion(nil);
                                                 }
                                                 
                                             }];
                                     } else if (completion) {
                                         completion(nil);
                                     }
                                 }];
    
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    // способ показа контроллера, использую UIAplication
    UIViewController* mainVc = [[[[UIApplication sharedApplication] windows] firstObject] rootViewController];
    
    [mainVc presentViewController:nav
                         animated:YES
                       completion:nil];
}

- (void) getUser:(NSString*) userID
       onSuccess:(void (^)(KVUser* user))success
       onFailure:(void (^)(NSError* error, NSInteger statusCode))failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            userID,         @"user_ids",
                            @"photo_50",    @"fields",
                            @"nom",         @"name_case", nil];
    
    [self.requestOperationManager GET:@"users.get"
                           parameters:params
                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                  
                                  NSLog(@"JSON: %@", responseObject);
                                  
                                  NSArray* dictionaryArray = [responseObject
                                                              objectForKey:@"response"];
                                  
                                  if ([dictionaryArray count] > 0) {
                                      KVUser* user = [[KVUser alloc] initWithServerResponse:[dictionaryArray firstObject]];
                                      if (success) {
                                          success(user);
                                      }
                                  } else {
                                      
                                      if (failure) {
                                          failure(nil, operation.response.statusCode);
                                      }
                                      
                                  }
                                  
                              }
                              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                  NSLog(@"Error: %@", error);
                                  
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                                  
                              }];
}

// запрос на получение записей со стены
- (void) getWall:(NSString*) userID
      withOffset:(NSInteger) offset
           count:(NSInteger) count
       onSuccess:(void(^)(NSArray* posts)) success
       onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.accessToken.userID,    @"owner_id",
                            @(count),                   @"count",
                            @(offset),                  @"offset",
                            @"all",                     @"filter", nil];
    
    [self.requestOperationManager GET:@"wall.get"
                           parameters:params
                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                  
                                  NSLog(@"JSON: %@", responseObject);
                                  
                                  NSArray* dictionaryArray = [responseObject objectForKey:@"response"];
                                  
                                  if ([dictionaryArray count] > 1) {
                                      dictionaryArray = [dictionaryArray subarrayWithRange:NSMakeRange(1, (int)[dictionaryArray count] - 1)];
                                  } else {
                                      dictionaryArray = nil;
                                  }
                                  
                                  NSMutableArray* objectsArray = [NSMutableArray array];
                                  
                                  for (NSDictionary* dic in dictionaryArray) {
                                      KVPost* post = [[KVPost alloc] initWithServerResponse:dic];
                                      [objectsArray addObject:post];
                                  }
                                  
                                  // если запрос завершился, возврат массива
                                  if (success) {
                                      success(objectsArray);
                                  }
                                  
                              }
                              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                  
                                  NSLog(@"Error: %@", error);
                                  
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                                  
                              }];
    
}

// запрос на получение комментов для поста
- (void) getCommentOnUserID:(NSString*) userID
                   withPost:(NSString*) postID
                  onSuccess:(void(^)(NSArray* coments)) success
                  onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.accessToken.userID,     @"owner_id",
                            postID,     @"post_id",
                            @(1),       @"need_likes",
                            @"asc",     @"sort", nil];
    
    [self.requestOperationManager GET:@"wall.getComments"
                           parameters:params
                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                  
                                  NSLog(@"JSON: %@", responseObject);
                                  
                                  NSArray* dictionaryArray = [responseObject objectForKey:@"response"];
                                  
                                  if ([dictionaryArray count] > 1) {
                                      dictionaryArray = [dictionaryArray subarrayWithRange:NSMakeRange(1, (int)[dictionaryArray count] - 1)];
                                  } else {
                                      dictionaryArray = nil;
                                  }
                                  
                                  NSMutableArray* objectsArray = [NSMutableArray array];
                                  
                                  for (NSDictionary* dic in dictionaryArray) {
                                      KVComment* comm = [[KVComment alloc] initWithServerResponse:dic];
                                      [objectsArray addObject:comm];
                                  }
                                  
                                  // если запрос завершился, возврат массива
                                  if (success) {
                                      success(objectsArray);
                                  }
                                  
                              }
                              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                  
                                  NSLog(@"Error: %@", error);
                                  
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                                  
                              }];
    
}

// запрос на получение списка лайкнувших
- (void) getLikesOnUserID:(NSString*) userID
                 withPost:(NSString*) postID
                onSuccess:(void(^)(NSArray* users)) success
                onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.accessToken.userID,    @"owner_id",
                            postID,                     @"item_id",
                            @"post",                    @"type",
                            @(1),                       @"extended", nil];
    
    [self.requestOperationManager GET:@"likes.getList"
                           parameters:params
                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                  
                                  NSLog(@"JSON: %@", responseObject);
                                  
                                  NSArray* dictionaryArray = [[responseObject objectForKey:@"response"] objectForKey:@"items"];
                                  
                                  NSMutableArray* objectsArray = [NSMutableArray array];
                                  
                                  for (NSDictionary* dic in dictionaryArray) {
                                      KVUser* user = [[KVUser alloc] initWithServerResponse:dic];
                                      [objectsArray addObject:user];
                                  }
                                  
                                  // если запрос завершился, возврат массива
                                  if (success) {
                                      success(objectsArray);
                                  }
                                  
                              }
                              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                  
                                  NSLog(@"Error: %@", error);
                                  
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                                  
                              }];
    
}

// запрос на проверку лайка
- (void) getLikesWithPost:(NSString*) postID
                onSuccess:(void(^)(void)) success
                onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.accessToken.userID,    @"owner_id",
                            postID,                     @"item_id",
                            @"post",                    @"type",
                            self.accessToken.token,     @"access_token", nil];
    
    [self.requestOperationManager GET:@"likes.isLiked"
                           parameters:params
                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                  
                                  NSLog(@"JSON: %@", responseObject);
                                 
                                  BOOL isLike = [[responseObject objectForKey:@"response"] integerValue];
                                  
                                  if (isLike) {
                                      [self.requestOperationManager POST:@"likes.delete"
                                                              parameters:params
                                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                     
                                                                     NSLog(@"JSON: %@", responseObject);
                                                                     
                                                                 }
                                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                     
                                                                     NSLog(@"Error: %@", error);
                                                                     
                                                                     if (failure) {
                                                                         failure(error, operation.response.statusCode);
                                                                     }
                                                                     
                                                                 }];
                                  } else {
                                      
                                      [self.requestOperationManager POST:@"likes.add"
                                                              parameters:params
                                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                     
                                                                     NSLog(@"JSON: %@", responseObject);
                                                                     
                                                                 }
                                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                     
                                                                     NSLog(@"Error: %@", error);
                                                                     
                                                                     if (failure) {
                                                                         failure(error, operation.response.statusCode);
                                                                     }
                                                                     
                                                                 }];
                                      
                                  }
                                  
                                  
                                  
                              }
                              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                  
                                  NSLog(@"Error: %@", error);
                                  
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                                  
                              }];

    
    
    
}

// пост запрос
- (void) postText:(NSString*) text
           onWall:(NSString*) userID
        onSuccess:(void(^)(id result)) success
        onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.accessToken.userID,    @"owner_id",
                            text,                       @"message",
                            self.accessToken.token,     @"access_token", nil];
    
    [self.requestOperationManager POST:@"wall.post"
                            parameters:params
                               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                   
                                   NSLog(@"JSON: %@", responseObject);
                                   
                               }
                               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                   
                                   NSLog(@"Error: %@", error);
                                   
                                   if (failure) {
                                       failure(error, operation.response.statusCode);
                                   }
                                   
                               }];
    
}

// отправка сообщения
- (void) postMessage:(NSString*) text
              onUser:(NSString*) userID
           onSuccess:(void(^)(id result)) success
           onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            userID,                     @"user_id",
                            text,                       @"message",
                            self.accessToken.token,     @"access_token", nil];
    
    [self.requestOperationManager POST:@"messages.send"
                            parameters:params
                               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                   
                                   NSLog(@"JSON: %@", responseObject);
                                   
                               }
                               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                   
                                   NSLog(@"Error: %@", error);
                                   
                                   if (failure) {
                                       failure(error, operation.response.statusCode);
                                   }
                                   
                               }];
    
}

@end
