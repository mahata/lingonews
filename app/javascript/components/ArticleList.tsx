import React, { useState, useEffect } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { formatDate } from "../types";
import type { Article, Locale } from "../types";

interface Props {
  locale: Locale;
}

interface PaginatedResponse {
  articles: Article[];
  page: number;
  total_pages: number;
  total_count: number;
}

function Pagination({
  page,
  totalPages,
  onPageChange,
}: {
  page: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}) {
  if (totalPages <= 1) return null;

  const windowSize = 2;
  const pages: (number | "ellipsis-start" | "ellipsis-end")[] = [];
  const windowStart = Math.max(2, page - windowSize);
  const windowEnd = Math.min(totalPages - 1, page + windowSize);

  pages.push(1);

  if (windowStart > 2) {
    pages.push("ellipsis-start");
  }

  for (let i = windowStart; i <= windowEnd; i++) {
    pages.push(i);
  }

  if (windowEnd < totalPages - 1) {
    pages.push("ellipsis-end");
  }

  if (totalPages > 1) {
    pages.push(totalPages);
  }

  return (
    <nav className="pagination" aria-label="Pagination">
      <button
        disabled={page <= 1}
        onClick={() => onPageChange(page - 1)}
        className="pagination-btn"
        aria-label="Previous page"
      >
        &lsaquo;
      </button>
      {pages.map((p) =>
        typeof p === "string" ? (
          <span key={p} className="pagination-ellipsis">
            &hellip;
          </span>
        ) : (
          <button
            key={p}
            onClick={() => onPageChange(p)}
            className={`pagination-btn ${p === page ? "pagination-btn-active" : ""}`}
            aria-current={p === page ? "page" : undefined}
          >
            {p}
          </button>
        )
      )}
      <button
        disabled={page >= totalPages}
        onClick={() => onPageChange(page + 1)}
        className="pagination-btn"
        aria-label="Next page"
      >
        &rsaquo;
      </button>
    </nav>
  );
}

export function ArticleList({ locale }: Props) {
  const [searchParams, setSearchParams] = useSearchParams();
  const currentPage = Math.max(1, Number(searchParams.get("page")) || 1);

  const [articles, setArticles] = useState<Article[]>([]);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);
    fetch(`/api/articles?page=${currentPage}`)
      .then((res) => {
        if (!res.ok) {
          throw new Error(`Failed to fetch articles: ${res.status}`);
        }
        return res.json();
      })
      .then((data: PaginatedResponse) => {
        setArticles(data.articles);
        setTotalPages(data.total_pages);
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
  }, [locale, currentPage]);

  const handlePageChange = (page: number) => {
    if (page === 1) {
      setSearchParams({});
    } else {
      setSearchParams({ page: String(page) });
    }
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

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
        <>
          <ul>
            {articles.map((article) => (
              <li key={article.id} className="article-card">
                <Link to={`/articles/${article.id}`}>
                  <h2>
                    {locale === "en" ? article.title_en : article.title_ja}
                  </h2>
                  <time dateTime={article.published_at}>
                    {formatDate(article.published_at, locale)}
                  </time>
                </Link>
              </li>
            ))}
          </ul>
          <Pagination
            page={currentPage}
            totalPages={totalPages}
            onPageChange={handlePageChange}
          />
        </>
      )}
    </div>
  );
}
