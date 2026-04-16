import React, { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import type { Article, Locale, Sentence } from "../types";

interface Props {
  locale: Locale;
}

export function ArticleShow({ locale }: Props) {
  const { id } = useParams<{ id: string }>();
  const [article, setArticle] = useState<Article | null>(null);
  const [loading, setLoading] = useState(true);
  const [highlightedId, setHighlightedId] = useState<number | null>(null);

  useEffect(() => {
    fetch(`/api/articles/${id}`)
      .then((res) => {
        if (res.status === 404) {
          setArticle(null);
          setLoading(false);
          return null;
        }
        if (!res.ok) {
          throw new Error(`Failed to fetch article: ${res.status}`);
        }
        return res.json();
      })
      .then((data) => {
        if (data) {
          setArticle(data);
        }
        setLoading(false);
      })
      .catch((err) => {
        console.error("Failed to fetch article:", err);
        setArticle(null);
        setLoading(false);
      });
  }, [id]);

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  if (!article) {
    return <div className="error">Article not found.</div>;
  }

  const sentences = article.sentences || [];
  const primaryLang = locale;
  const secondaryLang: "en" | "ja" = locale === "en" ? "ja" : "en";

  return (
    <div className="article-show">
      <Link to="/" className="back-link">
        ← {locale === "en" ? "Back to articles" : "記事一覧に戻る"}
      </Link>

      <h1>{locale === "en" ? article.title_en : article.title_ja}</h1>
      <time dateTime={article.published_at}>
        {new Date(article.published_at).toLocaleDateString(
          locale === "en" ? "en-US" : "ja-JP",
          { year: "numeric", month: "long", day: "numeric" }
        )}
      </time>

      <div className="sentences">
        {sentences.map((sentence) => (
          <div
            key={sentence.id}
            className={`sentence-pair ${highlightedId === sentence.id ? "highlighted" : ""}`}
            tabIndex={0}
            onMouseEnter={() => setHighlightedId(sentence.id)}
            onMouseLeave={() => setHighlightedId(null)}
            onFocus={() => setHighlightedId(sentence.id)}
            onBlur={() => setHighlightedId(null)}
          >
            <p className="sentence-primary">
              {primaryLang === "en" ? sentence.body_en : sentence.body_ja}
            </p>
            <p
              className={`sentence-secondary ${highlightedId === sentence.id ? "visible" : ""}`}
            >
              {secondaryLang === "en" ? sentence.body_en : sentence.body_ja}
            </p>
          </div>
        ))}
      </div>

      {article.source_url && (
        <div className="source-link">
          <a
            href={article.source_url}
            target="_blank"
            rel="noopener noreferrer"
            aria-label={`${article.source_title || article.source || article.source_url} ${
              locale === "en" ? "(opens in a new tab)" : "（新しいタブで開きます）"
            }`}
          >
            {article.source_title || article.source || article.source_url}
          </a>
        </div>
      )}
    </div>
  );
}
