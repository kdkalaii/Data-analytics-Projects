
-- Hotel Billing SQL Project

-- Step 1: Create ProductDetails Table
CREATE TABLE ProductDetails (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    Price DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO ProductDetails VALUES (1001, 'Idly', 10);
INSERT INTO ProductDetails VALUES (1002, 'Dosa', 15);
INSERT INTO ProductDetails VALUES (1003, 'Tea', 5);
INSERT INTO ProductDetails VALUES (1004, 'Coffee', 8);
INSERT INTO ProductDetails VALUES (1005, 'Pongal', 20);

-- Step 2: Create Product Audit Table and Trigger
CREATE TABLE ProductAudit (
    AuditID INT IDENTITY(1,1),
    ProductID INT,
    OldPrice DECIMAL(10,2),
    NewPrice DECIMAL(10,2),
    UpdatedOn DATETIME
);

CREATE TRIGGER trg_UpdateProductPrice
ON ProductDetails
AFTER UPDATE
AS
BEGIN
    INSERT INTO ProductAudit(ProductID, OldPrice, NewPrice, UpdatedOn)
    SELECT d.ProductID, d.Price, i.Price, GETDATE()
    FROM deleted d
    JOIN inserted i ON d.ProductID = i.ProductID
    WHERE d.Price <> i.Price;
END;

-- Step 3: Stored Procedures

-- Procedure to Start the Billing
CREATE PROCEDURE BILL_Start
AS
BEGIN
    IF OBJECT_ID('tempdb..##BillTemp') IS NOT NULL
        DROP TABLE ##BillTemp;

    CREATE TABLE ##BillTemp (
        SrNo INT IDENTITY(1,1),
        ProductID INT,
        Quantity INT
    );
END;

drop procedure BILL_Start
-- Procedure to Add Item to the Bill
CREATE PROCEDURE BILL_Item
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    INSERT INTO ##BillTemp(ProductID, Quantity)
    VALUES (@ProductID, @Quantity);
END;

drop procedure BILL_Item

-- Procedure to Finalize the Bill and Show Output
CREATE PROCEDURE BILL_End
AS
BEGIN
    IF OBJECT_ID('tempdb..#BillOutput') IS NOT NULL
        DROP TABLE #BillOutput;

    SELECT 
        b.SrNo,
        b.ProductID,
        p.ProductName,
        b.Quantity,
        p.Price,
        (p.Price * b.Quantity) AS Total
    INTO #BillOutput
    FROM ##BillTemp b
    JOIN ProductDetails p ON b.ProductID = p.ProductID;

    SELECT * FROM #BillOutput;

    SELECT SUM(Total) AS GrandTotal FROM #BillOutput;
END;


drop procedure BILL_End


EXEC BILL_Start;
EXEC BILL_Item @ProductID = 1001, @Quantity = 2;
EXEC BILL_Item @ProductID = 1004, @Quantity = 1;

EXEC BILL_End;
