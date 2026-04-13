import React, { useState, useEffect, useCallback } from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ArticleList } from "./ArticleList";
import { ArticleShow } from "./ArticleShow";
import type { Locale } from "../types";

function getInitialLocale(): Locale {
  const cookie = document.cookie
    .split("; ")
    .find((row) => row.startsWith("locale="));
  const locale = cookie?.split("=")[1];
  return locale === "en" || locale === "ja" ? locale : "en";
}

export function App() {
  const [locale, setLocale] = useState<Locale>(getInitialLocale);

  const toggleLocale = useCallback(() => {
    const newLocale: Locale = locale === "en" ? "ja" : "en";
    document.cookie = `locale=${newLocale};path=/;max-age=${60 * 60 * 24 * 365}`;
    setLocale(newLocale);
  }, [locale]);

  return (
    <BrowserRouter>
      <div className="app">
        <header className="header">
          <div className="header-inner">
            <a href="/" className="logo">
              🫐 LingoNews
            </a>
            <button onClick={toggleLocale} className="locale-toggle">
              {locale === "en" ? "日本語に切替" : "Switch to English"}
            </button>
          </div>
        </header>
        <main className="main">
          <Routes>
            <Route path="/" element={<ArticleList locale={locale} />} />
            <Route
              path="/articles/:id"
              element={<ArticleShow locale={locale} />}
            />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}
