CREATE DATABASE Bank_Sol_3;
USE Bank_Sol_3;

-- Table structure for table Customer
CREATE TABLE `Customer` (
  `customerID` int,
  `customerName` varchar(64),
  PRIMARY KEY (`customerID`)
);

-- Table structure for table Account
CREATE TABLE `Account` (
  `accountID` int,
  `customerID` int,
  `balance` varchar(64),
  PRIMARY KEY (`accountID`)
);

-- Table structure for table Loan
CREATE TABLE `Loan` (
  `loanID` int,
  `amount` varchar(64),
  `customerID` int,
  PRIMARY KEY (`loanID`)
);

ALTER TABLE `Account`
  ADD CONSTRAINT `FK_Account_Customer_CustomerID_idx` FOREIGN KEY (`CustomerID`) REFERENCES `Customer` (`CustomerID`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `Loan`
  ADD CONSTRAINT `FK_Loan_Customer_CustomerID_idx` FOREIGN KEY (`CustomerID`) REFERENCES `Customer` (`CustomerID`) ON DELETE CASCADE ON UPDATE CASCADE;
