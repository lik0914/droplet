package glide

// from std import fs.*
// from std import io.*

// /*
//  * Copyright (C) 2012 The Android Open Source Project
//  *
//  * Licensed under the Apache License, Version 2.0 (the "License");
//  * you may not use this file except in compliance with the License.
//  * You may obtain a copy of the License at
//  *
//  *
//  * Unless required by applicable law or agreed to in writing, software
//  * distributed under the License is distributed on an "AS IS" BASIS,
//  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  * See the License for the specific language governing permissions and
//  * limitations under the License.
//  */

// /**
//  * Buffers input from an {@link InputStream} for reading lines.
//  *
//  * <p>This class is used for buffered reading of lines. For purposes of this class, a line ends
//  * with "\n" or "\r\n". End of input is reported by throwing {@code EOFException}. Unterminated
//  * line at end of input is invalid and will be ignored, the caller may use {@code
//  * hasUnterminatedLine()} to detect it after catching the {@code EOFException}.
//  *
//  * <p>This class is intended for reading input that strictly consists of lines, such as line-based
//  * cache entries or cache journal. Unlike the {@link java.io.BufferedReader} which in conjunction
//  * with {@link java.io.InputStreamReader} provides similar functionality, this class uses different
//  * end-of-input reporting and a more restrictive definition of a line.
//  *
//  * <p>This class supports only charsets that encode '\r' and '\n' as a single byte with value 13
//  * and 10, respectively, and the representation of no other character contains these values.
//  * We currently check in constructor that the charset is one of US-ASCII, UTF-8 and ISO-8859-1.
//  * The default charset is US_ASCII.
//  */
// public class StrictLineReader {
//   private static let CR: Byte = '\r';
//   private static let LF: Byte = '\n';

//   private let inputStream: StringReader;

//   private let mtx = ReentrantMutex()

//   /*
//    * Buffered data is stored in {@code buf}. As long as no exception occurs, 0 <= pos <= end
//    * and the data in the range [pos, end) is buffered for reading. At end of input, if there is
//    * an unterminated line, we set end == -1, otherwise end == pos. If the underlying
//    * {@code InputStream} throws an {@code IOException}, end may remain as either pos or -1.
//    */
//   private var buf: Option<Array<Byte>>;
//   private var pos: Int64 = 0;
//   private var end: Int64 = 0;

//   /**
//    * Constructs a new {@code LineReader} with the specified capacity and charset.
//    *
//    * @param in the {@code InputStream} to read data from.
//    * @param capacity the capacity of the buffer.
//    * @param charset the charset used to decode data. Only US-ASCII, UTF-8 and ISO-8859-1 are
//    * supported.
//    * @throws NullPointerException if {@code in} or {@code charset} is null.
//    * @throws IllegalArgumentException if {@code capacity} is negative or zero
//    * or the specified charset is not supported.
//    */
//   public init(inputStream: InputStream) {
//     this.inputStream = inputStream;
//     buf = Some(Array<Int64>(8192, item: 0));
//   }

//   /**
//    * Closes the reader by closing the underlying {@code InputStream} and
//    * marking this reader as closed.
//    *
//    * @throws IOException for errors when closing the underlying {@code InputStream}.
//    */
//   public func close(): Unit {
//     synchronized(mtx) {
//       if (match(buf) {
//         case Some(x) => true,
//         case _ => false
//       }) {
//         buf = None;
//         inputStream.close();
//       }
//     }
//   }

//   /**
//    * Reads the next line. A line ends with {@code "\n"} or {@code "\r\n"},
//    * this end of line marker is not included in the result.
//    *
//    * @return the next line from the input.
//    * @throws IOException for underlying {@code InputStream} errors.
//    * @throws EOFException for the end of source stream.
//    */
//   public String readLine() throws IOException {
//     synchronized (in) {
//       if (buf == null) {
//         throw new IOException("LineReader is closed");
//       }

//       // Read more data if we are at the end of the buffered data.
//       // Though it's an error to read after an exception, we will let {@code fillBuf()}
//       // throw again if that happens; thus we need to handle end == -1 as well as end == pos.
//       if (pos >= end) {
//         fillBuf();
//       }
//       // Try to find LF in the buffered data and return the line if successful.
//       for (int i = pos; i != end; ++i) {
//         if (buf[i] == LF) {
//           int lineEnd = (i != pos && buf[i - 1] == CR) ? i - 1 : i;
//           String res = new String(buf, pos, lineEnd - pos, charset.name());
//           pos = i + 1;
//           return res;
//         }
//       }

//       // Let's anticipate up to 80 characters on top of those already read.
//       ByteArrayOutputStream out = new ByteArrayOutputStream(end - pos + 80) {
//         @Override
//         public String toString() {
//           int length = (count > 0 && buf[count - 1] == CR) ? count - 1 : count;
//           try {
//             return new String(buf, 0, length, charset.name());
//           } catch (UnsupportedEncodingException e) {
//             throw new AssertionError(e); // Since we control the charset this will never happen.
//           }
//         }
//       };

//       while (true) {
//         out.write(buf, pos, end - pos);
//         // Mark unterminated line in case fillBuf throws EOFException or IOException.
//         end = -1;
//         fillBuf();
//         // Try to find LF in the buffered data and return the line if successful.
//         for (int i = pos; i != end; ++i) {
//           if (buf[i] == LF) {
//             if (i != pos) {
//               out.write(buf, pos, i - pos);
//             }
//             pos = i + 1;
//             return out.toString();
//           }
//         }
//       }
//     }
//   }

//   public boolean hasUnterminatedLine() {
//     return end == -1;
//   }

//   /**
//    * Reads new input data into the buffer. Call only with pos == end or end == -1,
//    * depending on the desired outcome if the function throws.
//    */
//   private void fillBuf() throws IOException {
//     int result = in.read(buf, 0, buf.length);
//     if (result == -1) {
//       throw new EOFException();
//     }
//     pos = 0;
//     end = result;
//   }
// }
