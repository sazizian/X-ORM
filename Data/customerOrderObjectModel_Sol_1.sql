CREATE DATABASE customerOrderObjectModel_Sol_1;
USE customerOrderObjectModel_Sol_1;

-- Table structure for table Customer
CREATE TABLE `Customer` (
  `customerID` int,
  `customerName` varchar(64),
  PRIMARY KEY (`customerID`)
);

-- Table structure for table Order
CREATE TABLE `Order` (
  `orderID` int,
  `customerID` int,
  `orderValue` varchar(64),
  PRIMARY KEY (`orderID`)
);

-- Table structure for table PreferredCustomer
CREATE TABLE `PreferredCustomer` (
  `customerID` int,
  `discount` varchar(64),
  PRIMARY KEY (`customerID`)
);

ALTER TABLE `Order`
  ADD CONSTRAINT `FK_Order_Customer_CustomerID_idx` FOREIGN KEY (`CustomerID`) REFERENCES `Customer` (`CustomerID`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `PreferredCustomer`
  ADD CONSTRAINT `FK_PreferredCustomer_Customer_CustomerID_idx` FOREIGN KEY (`CustomerID`) REFERENCES `Customer` (`CustomerID`) ON DELETE CASCADE ON UPDATE CASCADE;
