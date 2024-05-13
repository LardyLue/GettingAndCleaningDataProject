# Load Packages and get the Data
library(dplyr)
library(data.table)

path <- getwd()
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(url, file.path(path, "dataFiles.zip"))
unzip(zipfile = "dataFiles.zip")

# Load activity labels + features
activityLabels <- fread(file.path(path, "UCI HAR Dataset/activity_labels.txt")
                        , col.names = c("classLabels", "activityName"))
features <- fread(file.path(path, "UCI HAR Dataset/features.txt")
                  , col.names = c("index", "featureNames"))
featuresDesired <- grep("(mean|std)\\(\\)", features[, featureNames])
featuresFull <- features[featuresDesired, featureNames]
featuresFull <- gsub('[()]', '', featuresFull)

# Load train datasets
train <- fread(file.path(path, "UCI HAR Dataset/train/X_train.txt"))[, featuresDesired, with = FALSE]
data.table::setnames(train, colnames(train), featuresFull)
trainActivities <- fread(file.path(path, "UCI HAR Dataset/train/Y_train.txt")
                         , col.names = c("Activity"))
trainSubjects <- fread(file.path(path, "UCI HAR Dataset/train/subject_train.txt")
                       , col.names = c("SubjectNum"))
train <- cbind(trainSubjects, trainActivities, train)

# Load test datasets
test <- fread(file.path(path, "UCI HAR Dataset/test/X_test.txt"))[, featuresDesired, with = FALSE]
data.table::setnames(test, colnames(test), featuresFull)
testActivities <- fread(file.path(path, "UCI HAR Dataset/test/Y_test.txt")
                        , col.names = c("Activity"))
testSubjects <- fread(file.path(path, "UCI HAR Dataset/test/subject_test.txt")
                      , col.names = c("SubjectNum"))
test <- cbind(testSubjects, testActivities, test)

# merge datasets
mergedTrainTest <- rbind(train, test)

# Convert classLabels to activityName basically. More explicit. 
mergedTrainTest[["Activity"]] <- factor(mergedTrainTest[, Activity]
                                 , levels = activityLabels[["classLabels"]]
                                 , labels = activityLabels[["activityName"]])

mergedTrainTest[["SubjectNum"]] <- as.factor(mergedTrainTest[, SubjectNum])
mergedTrainTest <- reshape2::melt(data = mergedTrainTest, id = c("SubjectNum", "Activity"))
mergedTrainTest <- reshape2::dcast(data = mergedTrainTest, SubjectNum + Activity ~ variable, fun.aggregate = mean)

data.table::fwrite(x = mergedTrainTest, file = "TidyData.txt", quote = FALSE)