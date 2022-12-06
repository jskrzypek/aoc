(ns
 y2022.d6
 (:require
  [aoc-util.tools
   :refer
   [create-next-day
    download-description
    get!
    open-browser
    submit-first!
    submit-second!]]
  [aoc-util.utils :refer [parse-int line-process] :as utils]
  [clojure.edn :refer [read-string] :as edn]
  [clojure.string :as st]))

(def input (first (get!)))

(defn find-start
  [s]
  (loop [ct 0
         s s
         mem ""]
    (prn ct (apply str (take 10 s)) mem)
    (if (= 4 (-> mem st/trim count))
      ct
      (recur (inc ct)
             (apply str (drop 1 s))
             (str
              " "
              (->> s
                   first
                   str
                   re-pattern
                   (st/split mem)
                   last
                   st/trim
                   (take-last 3)
                   (apply str))
              (first s)
              " ")))))

(comment
  (find-start input)
  input
  (download-description)
  (submit-first! 1779)
  )

(comment
  (download-description)
  (submit-second!)
  )

(comment
  (create-next-day)
  )

