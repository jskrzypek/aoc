(ns
 y2021.d4
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

(def input (get!))

(comment (download-description) (submit-first!))

(comment (download-description) (submit-second!))

(comment (create-next-day))

