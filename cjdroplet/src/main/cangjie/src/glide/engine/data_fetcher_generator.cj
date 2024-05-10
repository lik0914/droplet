package glide.engine

/**
   * Called when the generator has finished loading data from a {@link
   * com.bumptech.glide.load.data.DataFetcher}.
   */
public interface FetcherReadyCallback {

    /** Requests that we call startNext() again on a Glide owned thread. */
    func reschedule(): Unit;

    /**
     * Notifies the callback that the load is complete.
     *
     * @param sourceKey The id of the loaded data.
     * @param data The loaded data, or null if the load failed.
     * @param fetcher The data fetcher we attempted to load from.
     * @param dataSource The data source we were loading from.
     * @param attemptedKey The key we were loading data from (may be an alternate).
     */
    func onDataFetcherReady(
        sourceKey: AnyKey,
        data: Option<Any>,
        dataSource: DataSource
    ): Unit;

    /**
     * Notifies the callback when the load fails.
     *
     * @param attemptedKey The key we were using to load (may be an alternate).
     * @param e The exception that caused the load to fail.
     * @param fetcher The fetcher we were loading from.
     * @param dataSource The data source we were loading from.
     */
    func onDataFetcherFailed(
    ): Unit;
  }

public interface DataFetcherGenerator {

  /**
   * Attempts to a single new {@link com.bumptech.glide.load.data.DataFetcher} and returns true if a
   * {@link com.bumptech.glide.load.data.DataFetcher} was started, and false otherwise.
   */
  func startNext(): Bool;

  /**
   * Attempts to cancel the currently running fetcher.
   *
   * <p>This will be called on the main thread and should complete quickly.
   */
  func cancel(): Unit;
}
