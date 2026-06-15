CREATE TABLE Authors (
    AuthorID SERIAL PRIMARY KEY,
    FullName VARCHAR(100),
    Country VARCHAR(10)
);

CREATE TABLE Categories (
    CategoryID SERIAL PRIMARY KEY,
    CategoryName VARCHAR(50)
);

CREATE TABLE Books (
    BookID SERIAL PRIMARY KEY,
    Title VARCHAR(100),
    AuthorID INT REFERENCES Authors(AuthorID),
    CategoryID INT REFERENCES Categories(CategoryID),
    PublishedYear INT
);

CREATE TABLE Readers (
    ReaderID SERIAL PRIMARY KEY,
    FullName VARCHAR(100),
    Email VARCHAR(100)
);

CREATE TABLE Borrowings (
    BorrowID SERIAL PRIMARY KEY,
    BookID INT REFERENCES Books(BookID),
    ReaderID INT REFERENCES Readers(ReaderID),
    BorrowDate DATE,
    PenaltyFee DECIMAL(10, 2)
);

-- Insert

INSERT INTO Authors (FullName, Country) VALUES
('Jane Rowling', 'UK'),
('George Orwell', 'UK'),
('Stephen King', 'USA'),
('Jake Tolkien', 'UK');

INSERT INTO Categories (CategoryName) VALUES
('Fantasy'),
('Drama'),
('Horror'),
('Classic');

INSERT INTO Books (Title, AuthorID, CategoryID, PublishedYear) VALUES
('Harry Potter', 1, 1, 1997),
('1984', 2, 2, 1949),
('The Shining', 3, 3, 1977),
('The Lord of the Rings', 4, 1, 1954);

INSERT INTO Readers (FullName, Email) VALUES
('John King', 'john.king@example.com'),
('Jane Walter', 'jane.walter@example.com'),
('Bob Pie', 'bob.pie@example.com');

INSERT INTO Borrowings (BookID, ReaderID, BorrowDate, PenaltyFee) VALUES
(1, 1, '2026-05-01', 10.00),
(2, 2, '2026-05-15', 0.00),
(3, 1, '2026-05-20', 25.50),
(4, 3, '2026-06-01', 0.00),
(1, 3, '2026-06-05', 12.00),
(2, 1, '2026-06-10', 5.00);

-- Main part

WITH MainLibraryData AS (
    SELECT 
        c.CategoryName,
        b.Title AS BookTitle,
        b.PublishedYear,
        a.FullName AS AuthorName,
        r.FullName AS ReaderName,
        bw.PenaltyFee,
        bw.BorrowDate
    FROM Borrowings bw
    JOIN Books b ON bw.BookID = b.BookID
    JOIN Authors a ON b.AuthorID = a.AuthorID
    JOIN Categories c ON b.CategoryID = c.CategoryID
    JOIN Readers r ON bw.ReaderID = r.ReaderID
    WHERE bw.BorrowDate >= '2026-01-01'
)
-- З штрафами
SELECT 
    CategoryName,
    BookTitle,
    PublishedYear,
    AuthorName,
    COUNT(ReaderName) AS TimesBorrowed,
    SUM(PenaltyFee) AS TotalPenalties,
    'Has Penalties' AS Status
FROM MainLibraryData
WHERE PenaltyFee > 0
GROUP BY CategoryName, BookTitle, PublishedYear, AuthorName
UNION ALL
-- Книги без штрафіф
SELECT 
    CategoryName,
    BookTitle,
    PublishedYear,
    AuthorName,
    COUNT(ReaderName) AS TimesBorrowed,
    SUM(PenaltyFee) AS TotalPenalties,
    'No Penalties' AS Status
FROM MainLibraryData
WHERE PenaltyFee = 0
GROUP BY CategoryName, BookTitle, PublishedYear, AuthorName
ORDER BY TotalPenalties DESC