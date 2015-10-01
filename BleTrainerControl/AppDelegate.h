//
//  AppDelegate.h
//  BleTrainerControl
//
//  Created by William Minol on 23/09/2015.
//
//  Created by William Minol on 03/09/2015.
//  Copyright (c) 2015 Tacx. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "ViewController.h"

#import "BTLETrainerManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    BTLETrainerManager *btleTrainerManager;
}

@property (nonatomic, retain) BTLETrainerManager *btleTrainerManager;

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

