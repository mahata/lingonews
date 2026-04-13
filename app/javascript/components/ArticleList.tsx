import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import type { Article, Locale } from "../types";

interface Props {
  locale: Locale;
}

export function ArticleList({ locale }: Props) {
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/articles")
      .then((res) => {
        if (!res.ok) {
          throw new Error(`Failed to fetch articles: ${res.status}`);
        }
        return res.json();
      })
      .then((data) => {
        setArticles(data);
        setLoading(false);
      })
      .catch((err) => {
        console.error("Failed to fetch articles:", err);
        setError(
          locale === "en"
            ? "Failed to load articles. Please try again later."
            : "記事の読み込みに失敗しました。しばらくしてからもう一度お試しください。"
        );
        setLoading(false);
      });
  }, [locale]);

  if (loading) {
    return <div className="loading">Loading articles...</div>;
  }

  if (error) {
    return <div className="error">{error}</div>;
  }

  return (
    <div className="article-list">
      <h1>{locale === "en" ? "Latest News" : "最新ニュース"}</h1>
      {articles.length === 0 ? (
        <p>{locale === "en" ? "No articles yet." : "記事がありません。"}</p>
      ) : (
        <ul>
          {articles.map((article) => (
            <li key={article.id} className="article-card">
              <Link to={`/articles/${article.id}`}>
                <h2>{locale === "en" ? article.title_en : article.title_ja}</h2>
                <time dateTime={article.published_at}>
                  {new Date(article.published_at).toLocaleDateString(
                    locale === "en" ? "en-US" : "ja-JP",
                    { year: "numeric", month: "long", day: "numeric" }
                  )}
                </time>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
