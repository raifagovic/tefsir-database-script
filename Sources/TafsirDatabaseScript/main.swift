import Foundation
import SQLite

struct Chapter: Codable {
    let number: Int
    let name: String
    let placeOfRevelation: String
    let numberOfVerses: Int
    let verses: [Verse]
}

struct Verse: Codable {
    let number: Int
    let text: String
    let originalText: String
    let commentary: String
}

func createDatabase() -> Connection? {
    let fileURL = URL(fileURLWithPath: #file)
    let scriptDirectoryURL = fileURL.deletingLastPathComponent()
    let dbFileURL = scriptDirectoryURL.appendingPathComponent("tafsir.db")

    do {
        let db = try Connection(dbFileURL.path)
        
        try db.execute("""
            CREATE TABLE IF NOT EXISTS chapter (
                chapter_id INTEGER PRIMARY KEY,
                chapter_name TEXT,
                chapter_number INTEGER,
                place_of_revelation TEXT,
                number_of_verses INTEGER
            );
        """)

        try db.execute("""
            CREATE TABLE IF NOT EXISTS verse (
                verse_id INTEGER PRIMARY KEY,
                chapter_id INTEGER,
                verse_number INTEGER,
                verse_text TEXT,
                original_verse_text TEXT,
                FOREIGN KEY (chapter_id) REFERENCES chapter (chapter_id)
            );
        """)

        try db.execute("""
            CREATE TABLE IF NOT EXISTS commentary (
                commentary_id INTEGER PRIMARY KEY,
                verse_id INTEGER,
                commentary_text TEXT,
                FOREIGN KEY (verse_id) REFERENCES verse (verse_id)
            );
        """)
        
        print("Database and schema created successfully.")
        return db
    } catch {
        print("Error creating database: \(error)")
        return nil
    }
}

func fillDatabase() {
    guard let db = createDatabase() else {
        fatalError("Error creating database.")
    }
    
    // Step 1: Read JSON Data
    let levelsToNavigateUp = 4
    let currentScriptPath = URL(fileURLWithPath: #file)
    var commonParentDirectoryURL = currentScriptPath
    
    for _ in 0..<levelsToNavigateUp {
        commonParentDirectoryURL = commonParentDirectoryURL.deletingLastPathComponent()
    }

    let tafsirJsonFileURL = commonParentDirectoryURL.appendingPathComponent("TafsirScrapingScript/Sources/TafsirScrapingScript/tafsir.json")

    do {
        guard let jsonData = try? Data(contentsOf: tafsirJsonFileURL) else {
            print("Failed to read JSON data from the file.")
            return
        }
        
        let decoder = JSONDecoder()
        let chapters = try decoder.decode([Chapter].self, from: jsonData)
        
        // Step 2: Insert data
        insertChapterData(db: db, chapters: chapters)
        insertVerseData(db: db, chapters: chapters)
        
        print("Database filled successfully.")
        
    } catch {
        print("Error: \(error)")
    }
}

func insertChapterData(db: Connection, chapters: [Chapter]) {
    do {
        for chapter in chapters {
            try db.run("INSERT INTO chapter (chapter_number, chapter_name, place_of_revelation, number_of_verses) VALUES (?, ?, ?, ?)", chapter.number, chapter.name, chapter.placeOfRevelation, chapter.numberOfVerses)
        }
    } catch {
        print("Error inserting data into 'chapter' table: \(error)")
    }
}

func insertVerseData(db: Connection, chapters: [Chapter]) {
    do {
        for chapter in chapters {
            for verse in chapter.verses {
                try db.run("INSERT INTO verse (chapter_id, verse_number, verse_text, original_verse_text) VALUES (?, ?, ?, ?)", chapter.number, verse.number, verse.text, verse.originalText)
                
                // If commentary is available, insert into the 'commentary' table
                let verseId = db.lastInsertRowid
                try db.run("INSERT INTO commentary (verse_id, commentary_text) VALUES (?, ?)", verseId, verse.commentary)
            }
        }
    } catch {
        print("Error inserting data into 'verse' and 'commentary' tables: \(error)")
    }
}

fillDatabase()

