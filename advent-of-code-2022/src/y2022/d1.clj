(ns y2022.d1
 (:require
  [aoc-util.tools
   :refer
   [create-next-day
    download-description
    get!
    open-browser
    submit-first!
    submit-second!]]
  [aoc-util.utils :refer [#_parse-int line-process] :as utils]
  [clojure.edn :refer [read-string] :as edn]
  [clojure.string :as st]))


(def input (get!))

(defn parse-ints
  "Takes a string and tries to parse into an Integer, otherwise nil"
  [^String s]
  (println s)
  (if (string? s)
    (try
      (Integer/parseInt s)
      (catch NumberFormatException _ nil))
    (do (clojure.stacktrace/print-stack-trace (Exception. "foo") 4) (throw (IllegalArgumentException. "Not a string")))))

(defn most-cal?
  ([n]
   (->> (get!)
        (map parse-ints)
        (partition-by nil?)
        (filter (comp not nil? first))
        (map #(reduce + %))
        (sort >)
        (take n)))
  ([] (most-cal? 1)))


(comment
  (download-description)
  (submit-first! (most-cal? 1))
  )

(comment
  (download-description) 
  (submit-second! (reduce + (most-cal? 3)))
  )

(comment (create-next-day))

