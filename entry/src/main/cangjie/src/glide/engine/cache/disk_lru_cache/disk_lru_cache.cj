package glide.engine.cache.disk_lru_cache

from std import collection.*
from std import io.*
from std import fs.*
import glide.util.*
import glide.util.utils.*
from std import sync.*
from ohos import image.*
from ohos import base.*

public class DiskLruCache {
    public static let JOURNAL_FILE: String = "journal.m"
    public static let JOURNAL_FILE_TEMP: String = "journal.tmp"
    public static let JOURNAL_FILE_BACKUP: String = "journal.bkp"

    public static let MAGIC: String = "libcore.io.DiskLruCache"
    public static let VERSION_1: String = "1"

    public static let ANY_SEQUENCE_NUMBER: Int64 = -1

    private static let CLEAN = "CLEAN"
    private static let DIRTY = "DIRTY"
    private static let REMOVE = "REMOVE"
    private static let READ = "READ"
    
    public let directory: GlideFile;
    private let journalFile: GlideFile;
    private let journalFileTmp: GlideFile;
    private let journalFileBackup: GlideFile;
    private var appVersion: Int64 = 0;
    private var maxSize: Int64 = 0;
    public var valueCount: Int64 = 0;
    private var size: Int64 = 0;

    //适配
    //private var journalWriter: Option<StringWriter> = None
    private var journalWriter: Option<StringWriter<File>> = None
    private let lruEntries: CacheMap<String, Entry> = CacheMap<String, Entry>();

    private var redundantOpCount: Int64 = 0;
    private var nextSequenceNumber: Int64 = 0;

    public let mtx = ReentrantMutex()



    private DiskLruCache(directory: GlideFile, appVersion: Int64, valueCount: Int64, maxSize: Int64) {
        this.directory = directory;
        this.appVersion = appVersion;
        this.journalFile = GlideFile(directory, JOURNAL_FILE);
        this.journalFileTmp = GlideFile(directory, JOURNAL_FILE_TEMP);
        this.journalFileBackup = GlideFile(directory, JOURNAL_FILE_BACKUP);
        this.valueCount = valueCount;
        this.maxSize = maxSize;
    }

    /**
    * Opens the cache in {@code directory}, creating a cache if none exists
    * there.
    *
    * @param directory a writable directory
    * @param valueCount the number of values per cache entry. Must be positive.
    * @param maxSize the maximum number of bytes this cache should use to store
    * @throws IOException if reading or writing the cache directory fails
    */
    public static func openStatic(directory: GlideFile, appVersion: Int64, valueCount: Int64, maxSize: Int64): DiskLruCache {
        if (maxSize <= 0) {
            throw Exception("glide error: maxSize <= 0");
        }
        if (valueCount <= 0) {
            throw Exception("glide error: valueCount <= 0");
        }

        // If a bkp file exists, use it instead.
        var backupFile: GlideFile = GlideFile(directory, JOURNAL_FILE_BACKUP);
        // AppLog.error("openStatic 11")
        if (backupFile.exists()) {
            //  AppLog.error("openStatic 22")
            var journalFile: GlideFile = GlideFile(directory, JOURNAL_FILE);
            // If journal file also exists just delete backup file.
            if (journalFile.exists()) {
                backupFile.delete();
            } else {
                renameToStatic(backupFile, journalFile, false);
            }
        }

        // Prefer to pick up where we left off.
        // AppLog.error("openStatic 55")
        var cache: DiskLruCache = DiskLruCache(directory, appVersion, valueCount, maxSize);
        if (cache.journalFile.exists()) {
            // AppLog.error("openStatic 66")
            try {
                cache.readJournal();
                cache.processJournal();
                return cache;
            } catch (journalIsCorrupt: Exception) {
                // System.out
                //     .AppLog.error("DiskLruCache "
                //         + directory
                //         + " is corrupt: "
                //         + journalIsCorrupt.getMessage()
                //         + ", removing");
                // AppLog.error("glide errpr: DiskLruCache  ${journalIsCorrupt}");
                cache.delete();
                throw journalIsCorrupt
            }
        }

        // Create a new empty cache.
        // AppLog.error("openStatic 33")
        directory.mkdirs();
        cache = DiskLruCache(directory, appVersion, valueCount, maxSize);
        // AppLog.error("openStatic 44")
        cache.rebuildJournal();
        return cache;
    }

    private func readJournal(): Unit{
        // TODO 文件默认只支持UTF8 原版是 Util.US_ASCII
        //适配
        //var reader: StringReader = journalFile.getStringReader()
        var reader: StringReader<File> = journalFile.getStringReader()
        // AppLog.error("readJournal 1")
        try {
            var magic: String = reader.readln().getOrThrow();
            // AppLog.error("readJournal 11")
            var version: String = reader.readln().getOrThrow();
            // AppLog.error("readJournal 22")
            var appVersionString: String = reader.readln().getOrThrow();
            // AppLog.error("readJournal 33")
            var valueCountString: String = reader.readln().getOrThrow();
            // AppLog.error("readJournal 44")
            var blank: String = reader.readln().getOrThrow();
            // AppLog.error("readJournal 55")
            //if (!MAGIC.equals(magic) ||
            //    !VERSION_1.equals(version) ||
            //    !appVersion.toString().equals(appVersionString) ||
            //    !valueCount.toString().equals(valueCountString) ||
            //    !"".equals(blank)) {
            //    throw Exception("unexpected journal header: [${magic} version ${valueCountString} ${blank} ]");
            //}

            //适配
            if (!(MAGIC == magic) || !(VERSION_1 == version) || !(appVersion.toString() == appVersionString) || !(valueCount.toString() == valueCountString) || !("" == blank)) {
                throw Exception("unexpected journal header: [${magic} version ${valueCountString} ${blank} ]");
            }

            // AppLog.error("readJournal 2")

            var lineCount: Int64 = 0;
            while (true) {
                try {
                    readJournalLine(reader.readln().getOrThrow());
                    lineCount++;
                } catch (endOfJournal: Exception) {
                    break;
                }
            }

            journalFile.file.getOrThrow().close()

            redundantOpCount = lineCount - lruEntries.size();

            // AppLog.error("readJournal 3")

            // If we ended on a truncated line, rebuild the journal before appending to it.
            // if (reader.hasUnterminatedLine()) {
            //     rebuildJournal();
            // } else {
            //     journalWriter = Some(StringWriter(journalFile.file.getOrThrow()));
            // }

            journalWriter = Some(journalFile.getStringWriter());
        } finally {
            // Util.closeQuietly(reader);
            if(match(journalFile.file) {
                case Some(x) => true
                case _ => false
            }) {
                // AppLog.error("readJournal 4")
                // journalFile.file.getOrThrow().close()
            }
        }
    }

    private func readJournalLine(line: String): Unit {
        //适配
        //var firstSpace: Int64 = line.indexOf(' ').getOrThrow();
        var firstSpace: Int64 = line.indexOf(' '.toString()).getOrThrow()
        if (firstSpace == -1) {
            throw Exception("unexpected journal line: ${line}");
        }

        var keyBegin: Int64 = firstSpace + 1;
        //适配
        //var secondSpace: Option<Int64> = line.indexOf(' ', keyBegin);
        var secondSpace: Option<Int64> = line.indexOf(' '.toString(), keyBegin)
        let key: String;
        if (match(secondSpace) {
            case Some(x) => false
            case _ => true
        }) {
            //适配
            //key = line.substring(keyBegin);
            key = line[keyBegin..]
            if (firstSpace == REMOVE.size && line.startsWith(REMOVE)) {
                lruEntries.remove(key);
                return;
            }
        } else {
            //适配
            //key = line.substring(keyBegin, secondSpace.getOrThrow() - keyBegin);
            key = line[keyBegin .. secondSpace.getOrThrow()]
        }

        var entry: Option<Entry> = lruEntries.get(key);
        if (match(entry) {
            case Some(x) => false
            case _ => true
        }) {
            entry = Some(Entry(key, this));
            lruEntries.put(key, entry.getOrThrow());
        }

        var secondSpaceTrue: Bool = match(secondSpace) {
            case Some(x) => true
            case _ => false
        }
        var secondSpaceFalse: Bool = match(secondSpace) {
            case Some(x) => false
            case _ => true
        }
        if (secondSpaceTrue && firstSpace == CLEAN.size && line.startsWith(CLEAN)) {
            //适配
            //var parts: Array<String> = line.substring(secondSpace.getOrThrow() + 1).split(" ");
            var parts: Array<String> = line[(secondSpace.getOrThrow() + 1) ..].split(" ")
            entry.getOrThrow().readable = true;
            entry.getOrThrow().currentEditor = None;
            entry.getOrThrow().setLengths(parts);
        } else if (secondSpaceFalse && firstSpace == DIRTY.size && line.startsWith(DIRTY)) {
            entry.getOrThrow().currentEditor = Some(Editor(entry.getOrThrow(), this.valueCount));
        } else if (secondSpaceFalse && firstSpace == READ.size && line.startsWith(READ)) {
            // This work was already done by calling lruEntries.get().
        } else {
            throw Exception("unexpected journal line: " + line);
        }
    }

    /**
    * Computes the initial size and collects garbage as a part of opening the
    * cache. Dirty entries are assumed to be inconsistent and will be deleted.
    */
    private func processJournal(): Unit{
        deleteIfExistsStatic(journalFileTmp);
        var i = 0
        while(i < lruEntries.list.size) {
            var entry: Entry = lruEntries.list[i].v

            if (match(entry.currentEditor) {
                case Some(x) => false
                case _ => true
            }) {
                var t = 0
                while(t < valueCount) {
                    size += entry.lengths[t];
                    t++
                }
                i++
            } else {
                entry.currentEditor = None;
                var t = 0
                while(t < valueCount) {
                    deleteIfExistsStatic(entry.getCleanFile(t));
                    deleteIfExistsStatic(entry.getDirtyFile(t));
                    t++
                }
                lruEntries.remove(lruEntries.list[i].k)
            }
        }
    }

    /**
    * Creates a new journal that omits redundant information. This replaces the
    * current journal if it exists.
    */
    private func rebuildJournal(): Unit {
        synchronized(mtx) {
            if (match(journalWriter) {
                case Some(x) => true
                case _ => false
            }) {
                // closeWriter(journalWriter.getOrThrow());
            }

            //适配
            //var writer: StringWriter = journalFileTmp.getStringWriter()
            var writer: StringWriter<File> = journalFileTmp.getStringWriter()
            writer.write(MAGIC);
            writer.write("\n");
            writer.write(VERSION_1);
            writer.write("\n");
            writer.write(appVersion.toString());
            writer.write("\n");
            writer.write(valueCount.toString());
            writer.write("\n");
            writer.write("\n");

            var i=0
            while(i < lruEntries.list.size) {
                var entry: Entry = lruEntries.list[i].v

                if (match(entry.currentEditor) {
                    case Some(x) => true
                    case _ => false
                }) {
                    writer.write("${DIRTY}${' '}${entry.key}${'\n'}");
                } else {
                    writer.write("${CLEAN}${' '}${entry.key}${entry.getLengths()}${'\n'}");
                }

                i++
            }

            writer.flush()

            if (journalFile.exists()) {
                renameToStatic(journalFile, journalFileBackup, true);
            }
            renameToStatic(journalFileTmp, journalFile, false);
            journalFileBackup.delete();

            // AppLog.error(journalFile.getStringReader().readToEnd())

            journalWriter = Some(journalFile.getStringWriter())
        }
    }

    private static func deleteIfExistsStatic(file: GlideFile): Unit {
        if (file.exists() && !file.delete()) {
            throw Exception("glide error: deleteIfExistsStatic");
        }
    }

    private static func renameToStatic(fromFile: GlideFile, to: GlideFile, deleteDestination: Bool): Unit {
        if (deleteDestination) {
            deleteIfExistsStatic(to);
        }
        if (!fromFile.renameTo(to)) {
            throw Exception("glide error: renameTo");
        }
    }

    /**
    * Returns a snapshot of the entry named {@code key}, or null if it doesn't
    * exist is not currently readable. If a value is returned, it is moved to
    * the head of the LRU queue.
    */
    public func get(key: String): Option<Value> {
        synchronized(mtx) {
            //1 AppLog.error("glidelog- disk lru cache get 1 : ${key}")
            checkNotClosed();
            // AppLog.error("disk lru cache get 2")
            for(r in lruEntries.getIterator()) {
                //1 AppLog.error("glidelog- disk lru cache get 2 ${r}")
            }
            var entry: Option<Entry> = lruEntries.get(key);
            if (match(entry) {
                case Some(x) => false
                case _ => true
            }) {
                // AppLog.error("disk lru cache get none")
                return None;
            }

            // AppLog.error("disk lru cache get 3")
            if (!entry.getOrThrow().readable) {
                return None;
            }

            // AppLog.error("disk lru cache get 4")
            for(f in entry.getOrThrow().cleanFiles) {
                if (!f.exists()) {
                    return None;
                }
            }

            // AppLog.error("disk lru cache get 5")
            redundantOpCount++;
            journalWriter.getOrThrow().write(READ);
            journalWriter.getOrThrow().write(' ');
            journalWriter.getOrThrow().write(key);
            journalWriter.getOrThrow().write('\n');
            journalWriter.getOrThrow().flush()
            if (journalRebuildRequired()) {
                // 开线程
                // executorService.submit(cleanupCallable);
                executorServiceSubmit()
            }

            return Some(Value(key, entry.getOrThrow().sequenceNumber, entry.getOrThrow().cleanFiles, entry.getOrThrow().lengths, this));
        }
    }

    /**
    * Returns an editor for the entry named {@code key}, or null if another
    * edit is in progress.
    */
    public func edit(key: String): Option<Editor> {
        return edit(key, ANY_SEQUENCE_NUMBER);
    }

    public func edit(key: String, expectedSequenceNumber: Int64): Option<Editor> {
        synchronized(mtx) {
            // AppLog.error("edit 11")
            checkNotClosed();
            // AppLog.error("edit 55")
            var entry: Option<Entry> = lruEntries.get(key);
            // AppLog.error("edit 66")
            var entryNull: Bool = match(entry) {
                case Some(x) => false
                case _ => true
            }
            if (expectedSequenceNumber != ANY_SEQUENCE_NUMBER && (entryNull || 
            entry.getOrThrow().sequenceNumber != expectedSequenceNumber)) {
                // AppLog.error("edit 44")
                return None; // Value is stale.
            }
            if (entryNull) {
                entry = Some(Entry(key, this));
                lruEntries.put(key, entry.getOrThrow());
            } else if (match(entry.getOrThrow().currentEditor) {
                case Some(x) => true
                case _ => false
            }) {
                // AppLog.error("edit 33")
                return None; // Another edit is in progress.
            }

            // AppLog.error("edit 22")
            var editor: Editor = Editor(entry.getOrThrow(), this.valueCount);
            entry.getOrThrow().currentEditor = Some(editor);

            // Flush the journal before creating files to prevent file leaks.
            
            journalWriter.getOrThrow().write(DIRTY);
            journalWriter.getOrThrow().write(' ');
            journalWriter.getOrThrow().write(key);
            journalWriter.getOrThrow().write('\n');
            flushWriter(journalWriter.getOrThrow());
            return editor;
        }
    }

    /** Returns the directory where this cache stores its data. */
    public func getDirectory(): GlideFile {
        return directory;
    }

    /**
    * Returns the maximum number of bytes that this cache should use to store
    * its data.
    */
    public func getMaxSize(): Int64 {
        synchronized(mtx) {
            return maxSize;
        }
    }

    /**
    * Changes the maximum number of bytes the cache can store and queues a job
    * to trim the existing store, if necessary.
    */
    public func setMaxSize(maxSize: Int64): Unit {
        synchronized(mtx) {
            this.maxSize = maxSize;
            // 开线程
            // executorService.submit(cleanupCallable);
            executorServiceSubmit()
        }
    }

    /**
    * Returns the number of bytes currently being used to store the values in
    * this cache. This may be greater than the max size if a background
    * deletion is pending.
    */
    public func getSize(): Int64 {
        synchronized(mtx) {
            return size;
        }
    }

    public func completeEdit(editor: Editor, success: Bool): Unit {
        synchronized(mtx) {
            var entry: Entry = editor.entry;
            if (entry.currentEditor.getOrThrow() != editor) {
                throw Exception("glide error: completeEdit");
            }

            var i=0
            // If this edit is creating the entry for the first time, every index must have a value.
            if (success && !entry.readable) {
                i=0
                while(i < valueCount) {
                    if (!editor.written.getOrThrow()[i]) {
                        editor.abort();
                        throw Exception("Newly created entry didn't create value for index ${i}");
                    }
                    if (!entry.getDirtyFile(i).exists()) {
                        editor.abort();
                        return;
                    }
                    i++
                }
            }

            i=0
            while(i < valueCount) {
                var dirty: GlideFile = entry.getDirtyFile(i);
                if (success) {
                    if (dirty.exists()) {
                        var clean: GlideFile = entry.getCleanFile(i);
                        dirty.renameTo(clean);
                        var oldLength: Int64 = entry.lengths[i];
                        var newLength: Int64 = clean.length();
                        entry.lengths[i] = newLength;
                        size = size - oldLength + newLength;
                    }
                } else {
                    deleteIfExistsStatic(dirty);
                }

                i++
            }

            redundantOpCount++;
            entry.currentEditor = None;
            // entry.readable | success
            if (entry.readable || success) {
                entry.readable = true;
                journalWriter.getOrThrow().write(CLEAN);
                journalWriter.getOrThrow().write(' ');
                journalWriter.getOrThrow().write(entry.key);
                journalWriter.getOrThrow().write(entry.getLengths());
                journalWriter.getOrThrow().write('\n');

                if (success) {
                    entry.sequenceNumber = nextSequenceNumber;
                    nextSequenceNumber = nextSequenceNumber + 1
                }
            } else {
                lruEntries.remove(entry.key);
                journalWriter.getOrThrow().write(REMOVE);
                journalWriter.getOrThrow().write(' ');
                journalWriter.getOrThrow().write(entry.key);
                journalWriter.getOrThrow().write('\n');
            }
            flushWriter(journalWriter.getOrThrow());

            if (size > maxSize || journalRebuildRequired()) {
                // 开线程
                // executorService.submit(cleanupCallable);
                executorServiceSubmit()
            }
        }
    }

    public func executorServiceSubmit(): Unit {
        spawn {
            synchronized (mtx) {
                if (match(journalWriter) {
                    case Some(x) => false
                    case _ => true
                }) {
                    // Closed.
                }
                trimToSize();
                if (journalRebuildRequired()) {
                    rebuildJournal();
                    redundantOpCount = 0;
                }
            }
        }
    }

    /**
    * We only rebuild the journal when it will halve the size of the journal
    * and eliminate at least 2000 ops.
    */
    private func journalRebuildRequired(): Bool {
        let redundantOpCompactThreshold: Int64 = 2000;
        return redundantOpCount >= redundantOpCompactThreshold && redundantOpCount >= lruEntries.size();
    }

    /**
    * Drops the entry for {@code key} if it exists and can be removed. Entries
    * actively being edited cannot be removed.
    *
    * @return true if an entry was removed.
    */
    public func remove(key: String): Bool {
        synchronized(mtx) {
            checkNotClosed();
            var entry: Option<Entry> = lruEntries.get(key);
            if (match(entry) {
                case Some(x) => false
                case _ => true
            } || match(entry.getOrThrow().currentEditor) {
                case Some(x) => true
                case _ => false
            }) {
                return false;
            }

            var i=0
            while(i < valueCount) {
                var file: GlideFile = entry.getOrThrow().getCleanFile(i);
                if (file.exists() && !file.delete()) {
                    throw Exception("glide error: failed to delete ");
                }
                size -= entry.getOrThrow().lengths[i];
                entry.getOrThrow().lengths[i] = 0;

                i++
            }

            redundantOpCount++;
            journalWriter.getOrThrow().write(REMOVE);
            journalWriter.getOrThrow().write(' ');
            journalWriter.getOrThrow().write(key);
            journalWriter.getOrThrow().write('\n');
            journalWriter.getOrThrow().flush()

            lruEntries.remove(key);

            if (journalRebuildRequired()) {
                // 开线程
                // executorService.submit(cleanupCallable);
                executorServiceSubmit()
            }

            return true;
        }
    }

    /** Returns true if this cache has been closed. */
    public func isClosed(): Bool {
        synchronized(mtx) {
            return match(journalWriter) {
                case Some(x) => false
                case _ => true
            };
        }
        
    }

    private func checkNotClosed(): Unit {
        if (match(journalWriter) {
                case Some(x) => false
                case _ => true
            }) {
            throw Exception("glide error: cache is closed");
        }
    }

    /** Force buffered operations to the filesystem. */
    public func flush(): Unit {
        synchronized(mtx) {
            checkNotClosed();
            trimToSize();
            flushWriter(journalWriter.getOrThrow());
        }
    }

    /** Closes this cache. Stored values will remain on the filesystem. */
    public func close(): Unit{
        synchronized(mtx) {
            if (match(journalWriter) {
                case Some(x) => false
                case _ => true
            }) {
                return; // Already closed.
            }

            var i=0
            while(i < lruEntries.list.size) {
                var entry: Entry = lruEntries.list[i].v

                if (match(entry.currentEditor) {
                    case Some(x) => true
                    case _ => false
                }) {
                    entry.currentEditor.getOrThrow().abort();
                }

                i++
            }

            trimToSize();
            // closeWriter(journalWriter.getOrThrow());
            journalWriter = None;
        }
    }

    private func trimToSize(): Unit {
        var i=0
        while (size > maxSize) {
            remove(lruEntries.list[i].k);
        }
    }

    /**
    * Closes the cache and deletes all of its stored values. This will delete
    * all files in the cache directory including files that weren't created by
    * the cache.
    */
    public func delete(): Unit {
        close();
        directory.delete()
    }

    /**
    * Flushes the writer while whitelisting with StrictMode if necessary.
    *
    * <p>See b/71520172.
    */
    //适配
    //private static func flushWriter(writer: StringWriter): Unit {
    private static func flushWriter(writer: StringWriter<File>): Unit {
        writer.flush();
    }

}

public class Value {
    private let key: String;
    private let sequenceNumber: Int64;
    private let lengths: Array<Int64>;
    private let files: Array<GlideFile>;
    private let parent: DiskLruCache;

    public init(key: String, sequenceNumber: Int64, files: Array<GlideFile>, lengths: Array<Int64>, parent: DiskLruCache) {
      this.key = key;
      this.sequenceNumber = sequenceNumber;
      this.files = files;
      this.lengths = lengths;
      this.parent = parent
    }

    /**
     * Returns an editor for this snapshot's entry, or null if either the
     * entry has changed since this snapshot was created or if another edit
     * is in progress.
     */
    public func edit(): Option<Editor> {
      return parent.edit(key, sequenceNumber);
    }

    public func getFile(index: Int64): GlideFile {
        return files[index];
    }

    /** Returns the string value for {@code index}. */
    public func getString(index: Int64): String {
        //适配
        //var stringReader: StringReader = files[index].getStringReader()
        var stringReader: StringReader<File> = files[index].getStringReader()
        return stringReader.readToEnd()
    }

    /** Returns the byte length of the value for {@code index}. */
    public func getLength(index: Int64): Int64 {
      return lengths[index];
    }
}

public class Editor <: GlideAny<Editor> {
    public let entry: Entry;
    public let written: Option<Array<Bool>>;
    public var committed: Bool = false;

    public init(entry: Entry, valueCount: Int64) {
        this.entry = entry;
        if(!entry.readable) {
            this.written = Some(Array<Bool>(valueCount, item: false))
        } else {
            this.written = None
        }
    }

    /**
    * Returns an unbuffered input stream to read the last committed value,
    * or null if no value has been committed.
    */
    //适配
    //public func newInputStream(index: Int64): Option<StringReader> {
    public func newInputStream(index: Int64): Option<StringReader<File>> {
        synchronized(entry.parent.mtx) {
            if (entry.currentEditor != this) {
                throw Exception("glide error: getString error");
            }
            if (!entry.readable) {
                return None;
            }
            var clearFile: GlideFile = entry.getCleanFile(index)
            return Some(clearFile.getStringReader())
        }
    }

    /**
    * Returns the last committed value as a string, or null if no value
    * has been committed.
    */
    public func getString(index: Int64, mtx: ReentrantMutex): Option<String> {
        synchronized(entry.parent.mtx) {
            if (entry.currentEditor != this) {
                throw Exception("glide error: getString error");
            }
            if (!entry.readable) {
                return None;
            }
            var clearFile: GlideFile = entry.getCleanFile(index)

            if(match(clearFile.file) {
                case Some(x) => true
                case _ => false
            }) {
                return Some(clearFile.getStringReader().readToEnd())
            }

            return None
        }
    }

    public func getFile(index: Int64): GlideFile {
        synchronized (entry.parent.mtx) {
            if (entry.currentEditor != this) {
                throw Exception();
            }
            if (!entry.readable) {
                written.getOrThrow()[index] = true;
            }
            var dirtyFile: GlideFile = entry.getDirtyFile(index);
            entry.parent.directory.mkdirs();
            return dirtyFile;
        }
    }

    /** Sets the value at {@code index} to {@code value}. */
    public func set(index: Int64, value: String): Unit {
        //适配
        //var writer: StringWriter = getFile(index).getStringWriter()
        var writer: StringWriter<File> = getFile(index).getStringWriter()
        writer.write(value);
        writer.flush()
    }

    /**
    * Commits this edit so it is visible to readers.  This releases the
    * edit lock so another edit may be started on the same key.
    */
    public func commit(): Unit {
        // The object using this Editor must catch and handle any errors
        // during the write. If there is an error and they call commit
        // anyway, we will assume whatever they managed to write was valid.
        // Normally they should call abort.
        this.entry.parent.completeEdit(this, true);
        committed = true;
    }

    /**
    * Aborts this edit. This releases the edit lock so another edit may be
    * started on the same key.
    */
    public func abort(): Unit {
        this.entry.parent.completeEdit(this, false);
    }

    public func abortUnlessCommitted(): Unit {
        if (!committed) {
            try {
                abort();
            } catch (e: Exception) {
            }
        }
    }

    public func toString(): String {
        return "Editor : entry ${entry}\n"
    }

    public operator func ==(that: Editor): Bool {
        var i=0
        while(i<written.getOrThrow().size) {
            let a1: Bool = written.getOrThrow()[i]
            let a2: Bool = that.written.getOrThrow()[i]
            if(a1 != a2) {
                return false
            }
            i++
        }
        return true
    }

    public operator func !=(that: Editor): Bool {
        !(this == that)
    }

    public func hashCode(): Int64 {
        return Utils.hashCode(this.written.getOrThrow())
    }

}

public class Entry <: GlideAny<Entry> {

    public let parent: DiskLruCache;
    public let key: String;

    /** Lengths of this entry's files. */
    public let lengths: Array<Int64>;

    /** Memoized File objects for this entry to avoid char[] allocations. */
    public var cleanFiles: Array<GlideFile>;
    public var dirtyFiles: Array<GlideFile>;

    /** True if this entry has ever been published. */
    public var readable: Bool = false;

    /** The ongoing edit or null if this entry is not being edited. */
    public var currentEditor: Option<Editor> = None;

    /** The sequence number of the most recently committed edit to this entry. */
    public var sequenceNumber: Int64 = 0;

    public init(key: String, parent: DiskLruCache) {
        this.key = key;
        this.parent = parent;
        this.lengths = Array<Int64>(this.parent.valueCount, item: 0);
        cleanFiles = Array<GlideFile>(this.parent.valueCount, {i: Int64 => GlideFile()});
        dirtyFiles = Array<GlideFile>(this.parent.valueCount, {i: Int64 => GlideFile()});

        // The names are repetitive so re-use the same builder to avoid allocations.
        //适配
        //var fileBuilder: StringBuilder = StringBuilder(key).append('.');
        var fileBuilder: StringBuilder = StringBuilder(key)
        fileBuilder.append('.')
        var truncateTo: Int64 = fileBuilder.size;
        var i: Int64 = 0
        while(i < this.parent.valueCount) {
            fileBuilder.append(i);
            cleanFiles[i] = GlideFile(this.parent.directory, fileBuilder.toString());
            fileBuilder.append(".tmp");
            dirtyFiles[i] = GlideFile(this.parent.directory, fileBuilder.toString());

            // fileBuilder.setLength(truncateTo);
            //适配
            //Utils.setStringBuilderLength(fileBuilder, truncateTo)
            fileBuilder = Utils.setStringBuilderLength(fileBuilder, truncateTo)
            i++;
        }
    }

    public func getLengths(): String {
        var result: StringBuilder = StringBuilder();
        
        for (size in lengths) {
            //适配
            //result.append(' ').append(size);
            result.append(' ')
            result.append(size)
        }
        return result.toString();
    }

    /** Set lengths using decimal numbers like "10123". */
    public func setLengths(strings: Array<String>): Unit {
        if (strings.size != this.parent.valueCount) {
        // throw invalidLengths(strings);
            throw Exception("glide error: error !!!!!!!")
        }

        try {
            var i = 0
            while(i < strings.size) {
                lengths[i] = Integer.parseInt64(strings[i], 10);
                i++
            }
        } catch (e: Exception) {
        // throw invalidLengths(strings);
            throw Exception("glide error: error !!!!!!!")
        }
    }

    public func getCleanFile(i: Int64): GlideFile {
        return cleanFiles[i];
    }

    public func getDirtyFile(i: Int64): GlideFile {
        return dirtyFiles[i];
    }


    public func toString(): String {
        return "Entry : length ${lengths}\n"
    }

    public operator func ==(that: Entry): Bool {
        return this.key == that.key
    }

    public operator func !=(that: Entry): Bool {
        return this.key != that.key
    }

    public func hashCode(): Int64 {
      return this.key.hashCode()
    }
}
