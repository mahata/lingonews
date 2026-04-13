# Seed bilingual articles for LingoNews

Article.destroy_all

articles_data = [
  {
    title_en: "Japan Launches New Bullet Train Line Connecting Tokyo and Osaka in Under Two Hours",
    title_ja: "日本、東京・大阪間を2時間以内で結ぶ新幹線の新路線を開業",
    published_at: "2026-04-10",
    sentences: [
      {
        body_en: "Japan unveiled its latest bullet train line on Thursday, promising to cut travel time between Tokyo and Osaka to under two hours.",
        body_ja: "日本は木曜日、東京と大阪間の移動時間を2時間以内に短縮する最新の新幹線路線を発表しました。"
      },
      {
        body_en: "The new Chuo Shinkansen uses magnetic levitation technology, reaching speeds of up to 500 kilometers per hour.",
        body_ja: "新しい中央新幹線は磁気浮上技術を使用し、時速500キロメートルに達します。"
      },
      {
        body_en: "Passengers will travel through a series of tunnels that pass beneath the Japanese Alps.",
        body_ja: "乗客は日本アルプスの地下を通る一連のトンネルを通過します。"
      },
      {
        body_en: "The project took over fifteen years to complete and cost approximately nine trillion yen.",
        body_ja: "このプロジェクトは完成までに15年以上を要し、費用は約9兆円でした。"
      },
      {
        body_en: "Officials expect the new line to significantly boost tourism and business travel between the two cities.",
        body_ja: "関係者は、この新路線が両都市間の観光およびビジネス旅行を大幅に促進すると期待しています。"
      }
    ]
  },
  {
    title_en: "Scientists Discover New Deep-Sea Species in the Pacific Ocean",
    title_ja: "科学者が太平洋で新しい深海生物種を発見",
    published_at: "2026-04-08",
    sentences: [
      {
        body_en: "A team of marine biologists has discovered three previously unknown species living near hydrothermal vents in the Pacific Ocean.",
        body_ja: "海洋生物学者のチームが、太平洋の熱水噴出孔付近に生息する3つの未知の種を発見しました。"
      },
      {
        body_en: "The creatures were found at a depth of over four thousand meters during a six-week research expedition.",
        body_ja: "これらの生物は、6週間の調査遠征中に水深4000メートル以上の場所で発見されました。"
      },
      {
        body_en: "One of the new species is a translucent shrimp that glows faintly in the dark.",
        body_ja: "新種の一つは、暗闇でかすかに光る半透明のエビです。"
      },
      {
        body_en: "Researchers believe these organisms have adapted to survive extreme pressure and near-boiling temperatures.",
        body_ja: "研究者たちは、これらの生物が極端な圧力と沸点に近い温度に適応して生き延びていると考えています。"
      },
      {
        body_en: "The discovery highlights how much of the ocean remains unexplored and full of surprises.",
        body_ja: "この発見は、海洋がいかに未探索で驚きに満ちているかを浮き彫りにしています。"
      }
    ]
  },
  {
    title_en: "Global Coffee Prices Hit Record High Amid Supply Shortages",
    title_ja: "供給不足で世界のコーヒー価格が過去最高値を記録",
    published_at: "2026-04-05",
    sentences: [
      {
        body_en: "Coffee prices around the world have reached their highest levels in decades, driven by poor harvests in Brazil and Vietnam.",
        body_ja: "ブラジルとベトナムの不作により、世界のコーヒー価格は数十年ぶりの高水準に達しました。"
      },
      {
        body_en: "A combination of drought and unexpected frost has severely damaged coffee crops in major producing regions.",
        body_ja: "干ばつと予期せぬ霜の組み合わせが、主要な生産地域のコーヒー作物に深刻な被害を与えました。"
      },
      {
        body_en: "Industry analysts warn that consumers may see price increases of twenty to thirty percent at cafes and supermarkets.",
        body_ja: "業界アナリストは、カフェやスーパーマーケットで20〜30パーセントの値上げが起こる可能性があると警告しています。"
      },
      {
        body_en: "Some specialty roasters are already limiting purchases to ensure fair distribution among customers.",
        body_ja: "一部のスペシャリティロースターは、顧客間の公平な配分を確保するため、すでに購入制限を設けています。"
      },
      {
        body_en: "Experts say it may take two to three years for global supply to recover to normal levels.",
        body_ja: "専門家は、世界の供給が通常のレベルに回復するまでに2〜3年かかる可能性があると述べています。"
      }
    ]
  },
  {
    title_en: "Remote Work Continues to Reshape City Centers Worldwide",
    title_ja: "リモートワークが世界中の都市中心部を変え続けている",
    published_at: "2026-04-02",
    sentences: [
      {
        body_en: "Six years after the pandemic began, remote work remains a dominant force reshaping how cities function.",
        body_ja: "パンデミックの開始から6年が経ち、リモートワークは都市の機能を再形成する支配的な力であり続けています。"
      },
      {
        body_en: "Office vacancy rates in major cities like New York, London, and Tokyo remain significantly above pre-pandemic levels.",
        body_ja: "ニューヨーク、ロンドン、東京などの主要都市のオフィス空室率は、パンデミック前の水準を大幅に上回ったままです。"
      },
      {
        body_en: "Many former office buildings are being converted into residential apartments and mixed-use spaces.",
        body_ja: "多くの旧オフィスビルが住宅アパートや複合用途スペースに転換されています。"
      },
      {
        body_en: "Small businesses in downtown areas report lower foot traffic compared to the years before remote work became widespread.",
        body_ja: "ダウンタウンエリアの中小企業は、リモートワークが普及する前の年と比べて歩行者の数が少ないと報告しています。"
      },
      {
        body_en: "Urban planners are now designing neighborhoods that blend living, working, and leisure spaces more seamlessly.",
        body_ja: "都市計画者は現在、住居、仕事、レジャーのスペースをよりシームレスに融合させた地域を設計しています。"
      }
    ]
  }
]

articles_data.each do |data|
  article = Article.create!(
    title_en: data[:title_en],
    title_ja: data[:title_ja],
    published_at: data[:published_at]
  )

  data[:sentences].each_with_index do |sentence, index|
    article.sentences.create!(
      position: index + 1,
      body_en: sentence[:body_en],
      body_ja: sentence[:body_ja]
    )
  end
end

puts "Seeded #{Article.count} articles with #{Sentence.count} sentences."
